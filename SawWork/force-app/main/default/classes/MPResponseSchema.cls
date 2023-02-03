/**Author        Date        Description
Ruchika Sharma   29/07/17       Created class.
                SFDC-1791 : Validate/Integrate MP API and user registration process in salesforce
**/

public class MPResponseSchema {
	public String type_Z {get;set;} // in json: type
		public Integer status {get;set;} 
		public String title {get;set;} 
		public String detail {get;set;} 
		public String requestedApi {get;set;} 
		public String instance {get;set;} 
		public List<Errors> errors {get;set;} 
		public Boolean validResponse;

	public MPResponseSchema(Integer status,String title,Boolean validResponse){
		this.status = status;
		this.title = title;
		this.validResponse = validResponse;
	}
	public Boolean getValidResponse(){
		return validResponse;
	}
	public List<errors> getErrors(){
		return errors;
	}

    public String getTitle(){
		return title;
	}
	public static void consumeObject(JSONParser parser) {
		Integer depth = 0;
		do {
			JSONToken curr = parser.getCurrentToken();
			if (curr == JSONToken.START_OBJECT || curr == JSONToken.START_ARRAY) {
				depth++;
			} else if (curr == JSONToken.END_OBJECT || curr == JSONToken.END_ARRAY) {
				depth--;
			}
		} while (depth > 0 && parser.nextToken() != null);
	}

	public class Errors {
		public String title {get;set;} 
		public String detail {get;set;} 

		public Errors(JSONParser parser) {
			while (parser.nextToken() != JSONToken.END_OBJECT) {
				if (parser.getCurrentToken() == JSONToken.FIELD_NAME) {
					String text = parser.getText();
					if (parser.nextToken() != JSONToken.VALUE_NULL) {
						if (text == 'title') {
							title = parser.getText();
						} else if (text == 'detail') {
							detail = parser.getText();
						} else {
							System.debug(LoggingLevel.WARN, 'Errors consuming unrecognized property: '+text);
							consumeObject(parser);
						}
					}
				}
			}
		}
	}
	
		

		public MPResponseSchema createParser(JSONParser parser,MPResponseSchema mpRes) {
			if(mpRes!=null)
				while (parser.nextToken() != JSONToken.END_OBJECT) {
					if (parser.getCurrentToken() == JSONToken.FIELD_NAME) {
						String text = parser.getText();
						if (parser.nextToken() != JSONToken.VALUE_NULL) {
							if (text == 'type') {
								mpRes.type_Z = parser.getText();
							} else if (text == 'status') {
								mpRes.status = parser.getIntegerValue();
							} else if (text == 'title') {
								mpRes.title = parser.getText();
							} else if (text == 'detail') {
								mpRes.detail = parser.getText();
							} else if (text == 'requestedApi') {
								mpRes.requestedApi = parser.getText();
							}else if (text == 'instance') {
								mpRes.instance = parser.getText();
							}else if (text == 'errors') {
								mpRes.errors = new List<Errors>();
								while (parser.nextToken() != JSONToken.END_ARRAY) {
									errors.add(new Errors(parser));
								}
							} else {
								System.debug(LoggingLevel.Error, 'MPResponseSchema consuming unrecognized property: '+text);
								consumeObject(parser);
							}
						}
					}
				}
				return mpRes;
		}
	
	public static MPResponseSchema parse(String json,MPResponseSchema mpRes) {
		return mpRes.createParser(System.JSON.createParser(json), mpRes);
	}
}