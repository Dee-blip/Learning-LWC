public class NAPItems{
    private String query{get;set;}
    private Integer whereClauseCount {get;set;}
    public NAPItems() {
        query='Select Id, NAP_Page_Builder_Child__r.Title__c, NAP_Page_Builder_Child__r.Link__c, Order__c, NAP_Page_Builder_Parent__r.Title__c, NAP_Page_Builder_Child__r.Component_Type__c, NAP_Page_Builder_Parent__r.Description__c, NAP_Page_Builder_Child__c, NAP_Page_Builder_Parent__c, NAP_Page_Builder_Parent__r.Component_Type__c, NAP_Page_Builder_Child__r.Raw_HTML_Content__c,NAP_Page_Builder_Child__r.Name, NAP_Page_Builder_Parent__r.Name,NAP_Page_Builder_Child__r.Content_Type__c,NAP_Page_Builder_Child__r.Has_Language_Filters__c,NAP_Page_Builder_Child__r.Has_Tag_Filters__c,NAP_Page_Builder_Child__r.Is_File_Browser__c,NAP_Page_Builder_Child__r.Is_Nap_Search__c, NAP_Page_Builder_Child__r.News_Display_Type__c, NAP_Page_Builder_Child__r.Is_News_Filter__c,NAP_Page_Builder_Child__r.is_News_Subscription__c, NAP_Page_Builder_Child__r.Is_Lightning_Component__c, NAP_Page_Builder_Child__r.Lightning_Component_Name__c, NAP_Page_Builder_Child__r.Lightning_Flow_Name__c   from NAP_Page_Builder_Join__c where ';
        whereClauseCount = 0;
    }

    private void incrementWhereClauseCount()
    {
        if(whereClauseCount>0)
            query=query+' AND ';
        whereClauseCount += 1;
    }


    public NAPItems withParentInList(String bindVariable)
    {
        incrementWhereClauseCount();
        query = query+'NAP_Page_Builder_Parent__c in :'+ bindVariable;
        return this;
    }


    public NAPItems withParentName(String parentName)
    {
        incrementWhereClauseCount();
        query = query+'NAP_Page_Builder_Parent__r.Name =\''+parentName+'\'';
        return this;
    }




    public NAPItems withComponentType(String componentType)
    {
        incrementWhereClauseCount();
        query = query+'NAP_Page_Builder_Child__r.Component_Type__c=\''+componentType+'\'';
        return this;
    }

    /*

    public NAPItems withParent(String parentId)
    {
        incrementWhereClauseCount();
        query = query+'NAP_Page_Builder_Parent__c =\''+parentId+'\'';
        return this;
    }

    public NAPItems withParentComponentType(String cType)
    {
        incrementWhereClauseCount();
        query = query+'NAP_Page_Builder_Parent__r.Component_Type__c=\''+cType+'\'';
        return this;
    }


    public NAPItems withPageId(String pageId)
    {
        incrementWhereClauseCount();
        query = query+'NAP_Page_Builder_Parent__r.Name=\''+pageId+'\'';
        return this;
    }

    public NAPItems withChildPageBuilderId(String pbId)
    {
        incrementWhereClauseCount();
        query = query+'NAP_Page_Builder_Child__r.Name=\''+pbId+'\'';
        return this;
    }
    */



    public String getAll()
    {
        System.Debug('wowow' + this.query);
        return this.query+' order by Order__c ASC';
    }
}