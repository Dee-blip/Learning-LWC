/************************************************************************************************************
Author              :   VIKAS RUDRAPPA
Created             :   21-Jul-2020
Purpose             :   Wrapper class for Multipurpose lookup component

************************************************************************************************************
*/
public class SC_LookupSearchResult implements Comparable {
    private Id id; //Record Id
    private String sObjectType; //Object API Name
    private String icon; //Object icon
    private String title; //Record Name
    private String recordUrl; //Record URL
    
    public SC_LookupSearchResult(Id id, String sObjectType, String icon, String title, String recordUrl) {
        this.id = id;
        this.sObjectType = sObjectType;
        this.icon = icon;
        this.title = title;
        this.recordUrl = recordUrl;
    }
    
    @AuraEnabled
    public Id getId() {
        return id;
    }
    
    @AuraEnabled
    public String getSObjectType() {
        return sObjectType;
    }
    
    @AuraEnabled
    public String getIcon() {
        return icon;
    }
    
    @AuraEnabled
    public String getTitle() {
        return title;
    }
    
    @AuraEnabled
    public String getRecordUrl() {
        return recordUrl+'/view';
    }
    
    /**
    	* Allow to sort search results based on title(record name)
		* Use List<SC_LookupSearchResult>.sort() to sort based on record name
		* EXAMPLE : List<SC_LookupSearchResult> results = new List<SC_LookupSearchResult>(); 
			   		results.sort();
    */
    public Integer compareTo(Object compareTo) {
        SC_LookupSearchResult other = (SC_LookupSearchResult) compareTo;
        if (this.getTitle() == null) {
            return (other.getTitle() == null) ? 0 : 1;
        }
        if (other.getTitle() == null) {
            return -1;
        }
        return this.getTitle().compareTo(other.getTitle());
    }
}