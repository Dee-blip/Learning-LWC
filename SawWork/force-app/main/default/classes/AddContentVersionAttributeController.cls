/** Sonali Tandon -- SFDC-934 Some Design Gaps in File Filters --  Added duplicate check for attribute name - value pairs **/

public class AddContentVersionAttributeController
{
    private List<ContentVersionAttribute__c> attributes;
    public ContentVersion cv {get;set;}
    private String cvId;
    public ContentVersionAttribute__c newAttr {get;set;}
    public Boolean createMode {get;set;}
    private Map<String,String> mapOfAttributeValueToAttributeName;

    public AddContentVersionAttributeController()
    {
        createMode = false;
        cvId= ApexPages.currentPage().getParameters().get('ContentVersionId'); 
        cv = [Select id, Title from ContentVersion where id=:cvId];
        if(cv==null)
        {
             ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Wrong content ID specified', ''));
        }

        cvId = String.valueOf(cv.Id).substring(0,15);
    }

    public List<ContentVersionAttribute__c> getAttributes()
    {
         //SFDC-934 
        mapOfAttributeValueToAttributeName = new Map<String,String>();
        attributes                         = new List<ContentVersionAttribute__c>();
        for(ContentVersionAttribute__c contentVersionObj :[Select id, Name, Attribute_Name__c,Partner_Account__c,Attribute_Value__c from ContentVersionAttribute__c where ContentVersionId__c=:cvId or ContentVersionId__c=:cv.Id ORDER BY Attribute_Name__c ASC])
        {
            attributes.add(contentVersionObj);
            //  SFDC-934  -- create map of attribute value to attribute name for duplicate check 
            if(contentVersionObj.Attribute_Value__c!=null)
                mapOfAttributeValueToAttributeName.put(contentVersionObj.Attribute_Value__c, contentVersionObj.Attribute_Name__c);
            if(contentVersionObj.Partner_Account__c!=null)
                mapOfAttributeValueToAttributeName.put(contentVersionObj.Partner_Account__c, contentVersionObj.Attribute_Name__c);

        }
        //attributes = [Select id, Name, Attribute_Name__c,Partner_Account__c,Attribute_Value__c from ContentVersionAttribute__c where ContentVersionId__c=:cvId or ContentVersionId__c=:cv.Id];
        return attributes;
    }

    public Pagereference editAttribute()
    {
        String attr_id= ApexPages.currentPage().getParameters().get('attr_id'); 
        newAttr = [select id,name,Attribute_Name__c, Attribute_Value__c, Partner_Account__c,ContentVersionId__c from ContentVersionAttribute__c where id=:attr_id];
        createMode=true;
        return null;

    }

    public Pagereference deleteAttribute()
    {
        String attr_id= ApexPages.currentPage().getParameters().get('attr_id'); 

        ContentVersionAttribute__c cva = [select id from ContentVersionAttribute__c where id=:attr_id limit 1];
        if(cva!=null && cva.Id!=null){
            delete cva;
        }
        return null;
    }

    public Pagereference addNewAttribute()
    {
        newAttr = new ContentVersionAttribute__c(ContentVersionId__c=cv.Id);
        createMode=true;
        return null;
    }

   public PageReference saveAttribute()
    {   
        //if(mapOfAttributeValueToAttributeName.size()>0)
        //{
            if(mapOfAttributeValueToAttributeName.size()>0 && (mapOfAttributeValueToAttributeName.get(newAttr.Attribute_Value__c) == newAttr.Attribute_Name__c ||
            mapOfAttributeValueToAttributeName.get(newAttr.Partner_Account__c) == newAttr.Attribute_Name__c))
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Duplicate attibute name - value pair. Please select another attribute value!'));
            else
            {
                try
                {
                    upsert newAttr;
                }
                catch(Exception exc)
                {
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Error while Saving the Attribute :'+exc.getMessage(), ''));
                    return null;
                }
                createMode = false;
            }

        //}
            
        return null;
    }
    
    public PageReference cancelCreation()
    {
        newAttr = new ContentVersionAttribute__c(ContentVersionId__c=cv.Id);
        createMode = false;
        return null;
    }

}