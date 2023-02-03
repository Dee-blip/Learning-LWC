/** Sonali Tandon - 4/02/2016 - SFDC-246- CR 3262841
AlexaWebServiceParseClass that parses result received from alexa web service.
Called from CronPopulateAccountFocusAttributeClass job to calculate Focus__c attribute on Account to run once a momth. Focus is calculated based outside and inside traffic of primary country.
 Traffic data is consumed from Alexa Web Services.

 **/
public  class AlexaWebServiceParseClass{

	DomainUrlResponse domainUrlObj;
	CountryResponse countryResponse;
	ParsedResponse errorparseResponseObj;

	List<DomainUrlResponse> listofDomainUrlResponse		 = new List<DomainUrlResponse>();
	List<CountryResponse> temporaryListOfCountryResponse = new List<CountryResponse>();
	List<Account> accountForResponse = new List<Account>();
	List<CronPopulateAccountFocusAttributeClass.DataWrapper> listOfDataWrappers  = new List<CronPopulateAccountFocusAttributeClass.DataWrapper>();

	Map<String,String> mapOfCountrycodeToCountryName;
	Map<String, String> mapOfCountryNameToRegion;
	
	Integer count = 0;
	
public  class CountryResponse{

	String countryName;
	Decimal pageviews;
}

public  class DomainUrlResponse {

	String url;
	List<CountryResponse> listOfcountryResponse;
}

public class ParsedResponse {

	public List<CronPopulateAccountFocusAttributeClass.DataWrapper> dataWrappers;
	public String statusMessage;
}

public AlexaWebServiceParseClass (List<CronPopulateAccountFocusAttributeClass.DataWrapper> listOfDataWrappers){
	
	mapOfCountrycodeToCountryName		= new Map<String,String>();
	mapOfCountryNameToRegion 			= new Map<String, String>();

	this.listOfDataWrappers = listOfDataWrappers;

	System.debug('listOfDataWrappers' + listOfDataWrappers);

	//List<AlexaWebServiceCountryMapping__c> alexaMapping = AlexaWebServiceCountryMapping__c.getall().values(); //SFDC-2391
	for(Alexa_Web_Service_Country_Mapping__mdt alexaObj : [select Label,Region__c,Alexa_Country_Code__c from Alexa_Web_Service_Country_Mapping__mdt limit 50000]) //SFDC-2391
 	{
 		mapOfCountrycodeToCountryName.put(alexaObj.Alexa_Country_Code__c,alexaObj.Label); //SFDC-2391
 		mapOfCountryNameToRegion.put(alexaObj.Label, alexaObj.Region__c); //SFDC-2391
 	}

}


public ParsedResponse parseResponse(HttpResponse response)
 {

 	Dom.Document doc = response.getBodyDocument();
 	Dom.XMLNode root = doc.getRootElement();
 	
 	walkThrough(root);

 	// for the last URL
	if(temporaryListOfCountryResponse.size()> 0)		 
	{  
		domainUrlObj.listOfcountryResponse = new List<CountryResponse>(temporaryListOfCountryResponse);
		listofDomainUrlResponse.add(domainUrlObj);
		 // clear data 
     	temporaryListOfCountryResponse.clear();
	}

	// temporaryListOfCountryResponse is empty meaning there is no response for this dataurl
	else 
	{
	    CountryResponse countryResponse = new CountryResponse();
	    countryResponse.countryName = 'null';
	    countryResponse.pageviews = 0.0;

	    if(domainUrlObj!=null)
	    {
	    	domainUrlObj.listOfcountryResponse = new List<CountryResponse>();
	    	domainUrlObj.listOfcountryResponse.add(countryResponse);
	    	listofDomainUrlResponse.add(domainUrlObj);
	    }

	}
	
 	System.debug('final listofDomainUrlResponse' + listofDomainUrlResponse);

 	if(listofDomainUrlResponse.size()> 0)
 	{ 		
 		calculateFocusAttribute();

 		ParsedResponse successparseResponseObj = new ParsedResponse();
 		successparseResponseObj.dataWrappers   = new List<CronPopulateAccountFocusAttributeClass.DataWrapper>();
 		successparseResponseObj.dataWrappers   = listOfDataWrappers;
	 	successparseResponseObj.statusMessage = 'Success';

	 	System.debug('successparseResponseObj'+ successparseResponseObj);

 		return successparseResponseObj;
 	}

 	else
 	{

 		if(errorparseResponseObj!=null)
 		{
 			System.debug('errorparseResponseObj' + errorparseResponseObj);
 			return errorparseResponseObj;
 		}

 	} 
 	
 	return null;	
 
}


public void walkThrough(DOM.XMLNode node) {

	if(node.getName() == 'StatusCode')
	{
		if(node.getText()!= 'Success')
		{
			errorparseResponseObj = new ParsedResponse();
			errorparseResponseObj.dataWrappers = null;
		}
		
	}

	if(node.getName() == 'StatusMessage')
	{
		if(errorparseResponseObj!=null)
		{
			errorparseResponseObj.statusMessage = 'Error:' + node.getText();
			return;
		}

	}
	  // if the node is a country name attribute, create CountryResponse
	if(node.getAttributeCount() > 0 && node.getAttributeCount() > 0 && node.getName() == 'Country' 
		&& node.getAttributeKeyAt(0) == 'Code')
	{ 
        	
       if(mapOfCountrycodeToCountryName.containsKey(node.getAttributeValue(node.getAttributeKeyAt(0), node.getAttributeKeyNsAt(0))))
		{
			countryResponse = new CountryResponse();
			countryResponse.countryName = mapOfCountrycodeToCountryName.get(node.getAttributeValue(node.getAttributeKeyAt(0), node.getAttributeKeyNsAt(0)));
      	}
    }

 	 // if the node is a pageview
    if(node.getName() == 'PageViews')
    {
	    if(countryResponse!= null)
	     {
	     	if(node.getText()!=null && node.getText()!='')
	     	{
	     		String cleanString = node.getText().trim().remove('%');
	     		countryResponse.pageviews = Decimal.valueOf(cleanString);
		      	temporaryListOfCountryResponse.add(countryResponse);
	     	}		     
		      // reset 
		      countryResponse = null;
	      }
      }

      // if the node is a data url
     if(node.getName() == 'DataUrl')
     {
	  	// skip for the first iteration	
     	if(count!=0)
     	{
     		if(temporaryListOfCountryResponse.size()> 0)
		 	{  
		    	domainUrlObj.listOfcountryResponse = new List<CountryResponse>(temporaryListOfCountryResponse);
		     	// clear data 
		     	temporaryListOfCountryResponse.clear();
		     }
	     // temporaryListOfCountryResponse is empty meaning there is no response for this dataurl
	     	else 
	     	{
	     		CountryResponse countryResponse = new CountryResponse();
	     		countryResponse.countryName = 'null';
	     		countryResponse.pageviews = 0.0;
	     		domainUrlObj.listOfcountryResponse = new List<CountryResponse>();
	     		domainUrlObj.listOfcountryResponse.add(countryResponse);
	     	}

	     	listofDomainUrlResponse.add(domainUrlObj);
     	}
     	// create DomainUrlResponse
     	domainUrlObj = new DomainUrlResponse();
     	if(node.getText()!=null && node.getText()!='')
     		domainUrlObj.url = node.getText().split('/')[0];
	    count++;
     		       
    }
    	// recursive walkthrough
	 	for (Dom.XMLNode child: node.getChildElements())
	 		walkThrough(child);
	}



	public void calculateFocusAttribute()
	{

		String primaryCountrysRegion;
		Decimal otherRegionCount;
		Decimal primaryRegionCount;

		for(CronPopulateAccountFocusAttributeClass.DataWrapper data : listOfDataWrappers)
	 	{
	 		System.debug('data.website' + data.website);

	 		for(DomainUrlResponse domainObj : listofDomainUrlResponse)
	 		{
	 			if(data.website.containsIgnoreCase(domainObj.url))
	 			{
	 				System.debug('domainObj.url' + domainObj.url);
	 				primaryCountrysRegion = mapOfCountryNameToRegion.get(data.primaryCountry);

	 				System.debug('primaryCountrysRegion' + primaryCountrysRegion);

	 				otherRegionCount = 0;
					primaryRegionCount = 0;

					// calculate focus
					for(CountryResponse res : domainObj.listOfcountryResponse)
					{				
						if(res.countryName!= 'null' && res.pageviews!= 0.0 && primaryCountrysRegion!=null && mapOfCountryNameToRegion.containsKey(res.countryName))
						{
				
							if(!mapOfCountryNameToRegion.get(res.countryName).equalsIgnoreCase(primaryCountrysRegion))
								otherRegionCount += res.pageviews;
							else 
								primaryRegionCount += res.pageviews;			
						}

						// no response from alexa
						else if(res.countryName == 'null' && res.pageviews == 0.0)
						{
							otherRegionCount = -1;
							primaryRegionCount = -2;
						}	
					}

					System.debug('primaryRegionCount=' + primaryRegionCount + '  otherRegionCount=' + otherRegionCount);

					if(otherRegionCount >= primaryRegionCount && otherRegionCount >30)
						data.focus = 'Global';

					if(primaryRegionCount > otherRegionCount && primaryRegionCount > 30)
				 		data.focus ='Regional';

					if(otherRegionCount == -1 && primaryRegionCount == -2)
						data.focus ='Not Available';

					// if primary country is not present in mapping or it doesnt satisfy global/ regional/ not available
					if(data.focus == null)
						data.focus ='Country';

	 			}
	 		}
	 	}

	}


}