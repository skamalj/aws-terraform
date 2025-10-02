import base64
import json
from io import BytesIO
from PIL import Image
from pdf2image import convert_from_path
from openai import OpenAI

class SmartBankStatementAnalyzer:
    def __init__(self, vllm_base_url="http://localhost:8000/v1"):
        """Initialize the analyzer with vLLM OpenAI-compatible endpoint."""
        self.client = OpenAI(
            api_key="EMPTY",
            base_url=vllm_base_url,
        )
        self.model_name = "Qwen/Qwen2.5-VL-3B-Instruct"
    
    def pdf_to_base64_images(self, pdf_path, dpi=200):
        """Convert PDF pages to base64-encoded images."""
        try:
            pages = convert_from_path(pdf_path, dpi=dpi, fmt='jpeg')
            base64_images = []
            
            for i, page in enumerate(pages):
                buffered = BytesIO()
                page.save(buffered, format="JPEG", quality=85)
                img_bytes = buffered.getvalue()
                base64_str = base64.b64encode(img_bytes).decode('utf-8')
                base64_images.append(f"data:image/jpeg;base64,{base64_str}")
                
            return base64_images
        except Exception as e:
            raise Exception(f"Error converting PDF to images: {str(e)}")
    
    def get_first_page_prompt(self):
        """Prompt specifically for first page with header information."""
        return """
        This is the FIRST PAGE of a bank statement. Extract ALL header information and transaction data in JSON format:
        {
            "header_info": {
                "account_holder_name": "Full name of account holder",
                "account_number": "Complete account number",
                "bank_name": "Name of the bank",
                "bank_address": "Bank address if visible",
                "statement_period": {
                    "from_date": "Statement start date",
                    "to_date": "Statement end date"
                },
                "opening_balance": "Opening balance amount",
                "account_type": "Type of account (savings/current/etc)"
            },
            "transaction_summary": {
                "total_credits": "Total credit amount",
                "total_debits": "Total debit amount", 
                "closing_balance": "Closing balance amount"
            },
            "transactions": [
                {
                    "date": "Transaction date",
                    "description": "Transaction description",
                    "amount": "Transaction amount",
                    "type": "credit/debit",
                    "balance": "Running balance after transaction"
                }
            ]
        }
        
        Extract all visible information accurately. If any field is not visible, mark it as "not_visible".
        """
    
    def get_subsequent_page_prompt(self, page_number):
        """Prompt for subsequent pages that typically only have transactions."""
        return f"""
        This is PAGE {page_number} of a bank statement (continuation page). 
        This page likely contains ONLY transaction details with minimal header information.
        
        Extract the transaction data in JSON format:
        {{
            "page_info": {{
                "page_number": {page_number},
                "has_header_info": false,
                "continuation_page": true
            }},
            "transactions": [
                {{
                    "date": "Transaction date",
                    "description": "Transaction description", 
                    "amount": "Transaction amount",
                    "type": "credit/debit",
                    "balance": "Running balance after transaction"
                }}
            ],
            "page_balance_info": {{
                "starting_balance_on_page": "Balance at start of this page if visible",
                "ending_balance_on_page": "Balance at end of this page if visible"
            }}
        }}
        
        Focus on extracting transaction details. If there's any account summary information visible, include it.
        If any field is not visible, mark it as "not_visible".
        """
    
    def analyze_bank_statement_smart(self, pdf_path):
        """Analyze bank statement with page-specific processing."""
        try:
            base64_images = self.pdf_to_base64_images(pdf_path)
            all_results = []
            
            for i, base64_image in enumerate(base64_images):
                page_number = i + 1
                
                # Use different prompts for first page vs subsequent pages
                if page_number == 1:
                    prompt = self.get_first_page_prompt()
                    system_message = "You are analyzing the FIRST PAGE of a bank statement. Focus on header information AND transactions."
                else:
                    prompt = self.get_subsequent_page_prompt(page_number)
                    system_message = f"You are analyzing PAGE {page_number} of a bank statement. Focus primarily on transaction details."
                
                messages = [
                    {"role": "system", "content": system_message},
                    {
                        "role": "user",
                        "content": [
                            {
                                "type": "image_url",
                                "image_url": {"url": base64_image}
                            },
                            {
                                "type": "text", 
                                "text": prompt
                            }
                        ]
                    }
                ]
                
                response = self.client.chat.completions.create(
                    model=self.model_name,
                    messages=messages,
                    temperature=0.1,
                    max_tokens=2048,
                )
                
                page_result = {
                    "page": page_number,
                    "page_type": "header_page" if page_number == 1 else "transaction_page",
                    "analysis": response.choices[0].message.content
                }
                all_results.append(page_result)
            
            return all_results
            
        except Exception as e:
            raise Exception(f"Error analyzing bank statement: {str(e)}")
    
    def consolidate_multi_page_data(self, analysis_results):
        """Consolidate data from multiple pages into a single structure."""
        consolidated = {
            "header_info": {},
            "transaction_summary": {},
            "all_transactions": [],
            "page_count": len(analysis_results),
            "processing_summary": []
        }
        
        for result in analysis_results:
            try:
                # Parse JSON from each page
                page_data = json.loads(result["analysis"])
                
                # Extract header info from first page
                if result["page"] == 1 and "header_info" in page_data:
                    consolidated["header_info"] = page_data["header_info"]
                    consolidated["transaction_summary"] = page_data.get("transaction_summary", {})
                
                # Collect transactions from all pages
                if "transactions" in page_data:
                    for transaction in page_data["transactions"]:
                        transaction["source_page"] = result["page"]
                        consolidated["all_transactions"].append(transaction)
                
                consolidated["processing_summary"].append({
                    "page": result["page"],
                    "page_type": result["page_type"],
                    "transactions_found": len(page_data.get("transactions", [])),
                    "status": "success"
                })
                
            except json.JSONDecodeError as e:
                consolidated["processing_summary"].append({
                    "page": result["page"],
                    "page_type": result["page_type"],
                    "status": "json_parse_error",
                    "error": str(e)
                })
        
        return consolidated
    
    def get_transaction_count_by_page(self, pdf_path):
        """Quick analysis to get transaction count per page."""
        try:
            base64_images = self.pdf_to_base64_images(pdf_path)
            page_summaries = []
            
            for i, base64_image in enumerate(base64_images):
                page_number = i + 1
                
                prompt = f"""
                Count the number of transactions visible on this page {page_number} of the bank statement.
                
                Respond in this exact format:
                {{
                    "page": {page_number},
                    "transaction_count": <number>,
                    "has_header_info": <true/false>,
                    "page_type": "first_page" or "continuation_page"
                }}
                """
                
                messages = [
                    {
                        "role": "user",
                        "content": [
                            {
                                "type": "image_url",
                                "image_url": {"url": base64_image}
                            },
                            {
                                "type": "text", 
                                "text": prompt
                            }
                        ]
                    }
                ]
                
                response = self.client.chat.completions.create(
                    model=self.model_name,
                    messages=messages,
                    temperature=0.1,
                    max_tokens=256,
                )
                
                page_summaries.append({
                    "page": page_number,
                    "summary": response.choices[0].message.content
                })
            
            return page_summaries
            
        except Exception as e:
            raise Exception(f"Error getting page summaries: {str(e)}")

# Usage Examples
if __name__ == "__main__":
    analyzer = SmartBankStatementAnalyzer()
    
    # Example 1: Smart analysis with page-specific processing
    try:
        print("Analyzing bank statement with page-specific processing...")
        results = analyzer.analyze_bank_statement_smart("bank_statement.pdf")
        
        # Display results by page type
        for result in results:
            print(f"\n=== {result['page_type'].upper()} (Page {result['page']}) ===")
            print(result['analysis'])
            print("-" * 60)
        
        # Consolidate all data
        print("\n=== CONSOLIDATED DATA ===")
        consolidated = analyzer.consolidate_multi_page_data(results)
        print(json.dumps(consolidated, indent=2))
        
    except Exception as e:
        print(f"Error: {e}")
    
    # Example 2: Quick page summary
    try:
        print("\nGetting page summaries...")
        summaries = analyzer.get_transaction_count_by_page("bank_statement.pdf")
        for summary in summaries:
            print(f"Page {summary['page']}: {summary['summary']}")
            
    except Exception as e:
        print(f"Error: {e}")
