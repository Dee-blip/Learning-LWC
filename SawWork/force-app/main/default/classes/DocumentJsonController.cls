public without sharing class DocumentJsonController {

    public String jsonString { get; set; }
    
    public DocumentJsonController(){
    init();
    }
    
    public void init(){
        list<JsonWrapper> jsonwrapperlist = new list<JsonWrapper>();
        //https://akamai--c.na11.content.force.com/sfc/servlet.shepherd/version/download/068G0000000ZkUZ?asPdf=false&
        string OrgDiv=[select division from Organization][0].division;
        string publicTag='Public';
        string privateTag='Private';
        
        //list<string> tagslist = null;
        //if(ApexPages.currentPage().getParameters().get('tags')!=null)
        //{
        //tagslist=ApexPages.currentPage().getParameters().get('tags').split(',');
        //}
        
        //list<ContentDocument> ContentDocsList = new list<ContentDocument>();
        
        Id workspaceId = '058G0000000Toh3';
        
        list<Id> cdlist=new list<Id>();
        for(ContentWorkspaceDoc cwd:[SELECT ContentDocumentId,ContentWorkspaceId FROM ContentWorkspaceDoc where ContentWorkspaceId = :workspaceId])
        {
        cdlist.add(cwd.ContentDocumentId);
        }
        for(ContentDocument cd:[select id,LatestPublishedVersion.id,LatestPublishedVersion.title,LatestPublishedVersion.URL_for_Partners__c,LatestPublishedVersion.TagCsv from ContentDocument where id in :cdlist or parentid = :workspaceId])
        {
            JsonWrapper jw = generateJSONWrapper(cd, OrgDiv, publicTag, privateTag);
            if(jw!=null){
                jsonwrapperlist.add(jw);
            }
        }
        jsonString= JSON.serialize(jsonwrapperlist);

    }
    public JsonWrapper generateJSONWrapper(ContentDocument cd, String OrgDiv, String publicTag, String privateTag) {
        JsonWrapper jw=null;
        list<string> tagList=new list<string>();
        if(cd.LatestPublishedVersion.TagCsv!=null)
        for(string st:cd.LatestPublishedVersion.TagCsv.split(',')) {
            tagList.add(st.toLowerCase());
        }
        for(string str:tagList)
        {
            jw=null;
            if(publicTag.toLowerCase().contains(str))
            {   
                jw=new JsonWrapper(cd.LatestPublishedVersion.title,OrgDiv+'/sfc/servlet.shepherd/version/download/'+cd.LatestPublishedVersion.id,str.toLowerCase());
            }
            else if(privateTag.toLowerCase().contains(str))
            {
                jw=new JsonWrapper(cd.LatestPublishedVersion.title,cd.LatestPublishedVersion.URL_for_Partners__c,str.toLowerCase());
            }
        }    
        return jw;
    }
    public class JsonWrapper
        {
            //ContentDocument cd;
            string title;
            string URL;
            string tag;
            public JsonWrapper(string title_p,string URL_p,string tag_p)
            {
            title=title_p;
            URL=URL_p;
            tag=tag_p;
            }
        
        }
          //Modified By rsharma: commenting below test method, as it is present in non test class and hence causing deployment failure.
          
       // @isTest(SeeAllData=false)
        //static void DocumentJsonControllerTest() {

        /*ContentVersion contentVersionObj = new ContentVersion();
        contentVersionObj.ContentURL='http://www.google.com/';
        contentVersionObj.Title = 'Google.com';   
        contentVersionObj.Tagcsv='public,private';         
        insert contentVersionObj;*/
        //PageReference pageRef = Page.DocumentJson;
        //Test.setCurrentPageReference(pageRef);
        //DocumentJsonController fruc = new DocumentJsonController();
        
    //}
}