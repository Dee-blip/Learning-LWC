global with sharing class GSurveysController {
  
  public String surveyDelete                       {get; set;}
  public String newSurveyName                      {get; set;}
  public List<miniSurvey>allSurveys                {get; set;}
  public String username                           {get; set;}
  public String userId                             {get; set;}
  public String POD                                {get; set;}
  public List<Selectoption>  sitesPicklist         {get; set;} 
  public String surveySite                         {get; set;}
  public String showAddSitesMessage                {get; set;} 
  private String subdomain;
  private boolean useTopLevelDomain;
  
  //public boolean showERSSErrorMessage              {get;set;}
  public String siteInfo  {get; set;}
  
  public GSurveysController(ApexPages.StandardController stdController){
  
    
    username = System.Userinfo.getUserId();    
    setAllSurveys();
    setupSitesPicklist();
    siteInfo = Site.getDomain();
  }
  
  private void setupSitesPicklist(){
    String pathPrefix;
    sitesPicklist = new List<Selectoption>();
    List<Site> sites = [select Name, Subdomain, UrlPathPrefix from Site where Status = 'Active' ];
    setupDomain(sites);
    setupShowSites(sites.size());
    sitesPicklist.add(new Selectoption('--SELECT SITE--','--SELECT SITE--' ));
    for(Site s : sites){
      if(s.UrlPathPrefix == null)
        pathPrefix='EMPTY';
      else
        pathPrefix=s.UrlPathPrefix;
      sitesPicklist.add(new Selectoption(pathPrefix, s.Name));
    }
  }

  private void setupDomain(list <Site> sites){
    String subD;
    String tLevelDomain;
    useTopLevelDomain =false;
    if(sites!=null && sites.size()>0){
    /*  if(sites[0].TopLevelDomain != null && sites[0].TopLevelDomain.length()>0){
        subdomain = sites[0].TopLevelDomain;
        useTopLevelDomain=true;
      }
      else*/
     subdomain = sites[0].Subdomain;
    }
  }

  private void setupShowSites(Integer i){
    if(i>0){
      showAddSitesMessage = 'false';
    }
    else{
      showAddSitesMessage = 'false';
    }
  }

  private void setAllSurveys(){
   List<Survey__c> surveys = [Select Id, Name from Survey__c where IsDeleted = false  and recordType.Name!='RSS Template' order by Name];
  
   if(allSurveys == null){
      allSurveys = new List<miniSurvey>();
    }
   else{
      allSurveys.clear(); 
    } 
   for(Survey__c s : surveys){
      allSurveys.add(new miniSurvey(s.Name, s.Id));
    }
  }
  
    private static TestMethod void testGSurveysController(){
    SurveyTestingUtil tu = new SurveyTestingUtil();
    Apexpages.currentPage().getParameters().put('uId', Userinfo.getUserId());
    Apexpages.Standardcontroller stc;
    GSurveysController sc = new GSurveysController(stc);
    System.assert(sc.allSurveys.size()>0);
  }
  //Make new RSS Template
  public PageReference makeNewTemplate()
  {
    system.debug('###'+newSurveyName);
    
    String RecordTypeId;
    for(RecordType r  :[SELECT id FROM RecordType where name ='RSS Template'])
    {
        RecordTypeId= r.id;
    }
    Survey__c s = new Survey__c();
    s.Name = newSurveyName;
    s.RecordTypeId = RecordTypeId;
    s.UniqueName__c = GuidUtil.NewGuid();
    s.Submit_Response__c = ' temp ';
    try
    {
            List<Survey__c> lSurvey = [SELECT Id FROM Survey__c WHERE Name = :newSurveyName AND RSS_Published__c = true LIMIT 1];
            System.debug('#####' + lSurvey);
            if(lSurvey.size()>0)
            {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, 'Cannot save the template. Published template already exists with same name'));
                return null;
            }
    insert s;
    return new Pagereference('/apex/RSSEditTemplate?id='+s.Id);
    }
    catch(Exception e)
    {
    system.assertEquals('RSS__' +e,null);
    }
    return null;
  }
  public Pagereference makeNewSurvey(){   
    if(newSurveyName==null){
     POD='';
     return null;
    }
    /*if(surveySite == '--SELECT SITE--'){
     POD='';
     return null;
    }*/
    
    String urlPrefix = setupUrlPrefix(surveySite);
    String domain = setupDomainForSurvey(POD);
    String urlToSave= domain+'/'+urlPrefix+'TakeSurvey?';
    //Vineet - if record type is RSS Template Call makeNewTemplate()
        String RecordTypeID = ApexPages.CurrentPage().getParameters().get('RecordType');
        String RSSTemplateRecordType;
        for(RecordType r  :[SELECT name FROM RecordType where id =:RecordTypeID])
        {
        RSSTemplateRecordType = r.name;
        }

        if(RSSTemplateRecordType== 'RSS Template')
        {
           return makeNewTemplate();
        }
    //Vineet
    Survey__c s = new Survey__c();
    s.Name = newSurveyName;
    s.URL__c = urlToSave;
    s.Submit_Response__c = 'empty';
    s.thankYouText__c = 'Your survey has been submitted. Thank you for taking our survey.';
    s.thankYouLink__c='http://www.salesforce.com';

    try{
     insert s;
     createAnonSurveyTaker(s.Id);     
     return new Pagereference('/apex/SurveyPage?id='+s.Id);
     
    }catch(Exception e){
      return null;
    }
  }
  public String location { get { if(location==null) { location = ''; }return location;}set;}
  //True if the record type is RSS Template. Also sets the location to redirect to. Vineet
  public Boolean getIsRecordTypeRSSTemplate()
  {
      try
      {
        String RecordTypeID = ApexPages.CurrentPage().getParameters().get('RecordType');
        String RSSTemplateRecordType;
        for(RecordType r  :[SELECT name FROM RecordType where id =:RecordTypeID])
        {
            RSSTemplateRecordType = r.name;
        }

        if(RSSTemplateRecordType== 'RSS Template')
        {
           
            location ='/apex/'+'RSSCreateNewTemplate';
            return true;
        }
        
      }
      catch(Exception e)
      {
      
      }
      return false;
  }
  private static void createAnonSurveyTaker(String surveyId){
     list <SurveyTaker__c> sTakers = [select id from SurveyTaker__c where Survey__c = :surveyId and Contact__c = null and Case__c = null];
     if(sTakers != null && sTakers.size()>0)
       return;
     SurveyTaker__c st = new SurveyTaker__c();      
     st.Case__c = null;
     st.Survey__c = surveyId;
     st.Contact__c = null;
     insert st;
  }
  
  private String setupDomainForSurvey(String pod){
    if(pod != 'NO_POD' && !useTopLevelDomain && checkSubdomain(subdomain)){
      return 'http://'+subdomain+'.'+pod+'.force.com';
    }
    else if(pod != 'NO_POD' && useTopLevelDomain && checkSubdomain(subdomain)){
      return 'http://'+subdomain+'.'+pod;
    }
    else if(useTopLevelDomain) {
      return 'http://'+subdomain;   
    }
    else{
      return 'http://'+subdomain+'.force.com';
    }
  }
  
  private boolean checkSubdomain(String subdomain){
    if(subdomain == null)
     return false;
    else if (subdomain.contains('developer-edition'))
     return true;
    else
     return false;
  }
  
  private String setupUrlPrefix(String site){
    if(site == null || site=='EMPTY')
     return '';
    else
     return site+'/';
  }

  public Pagereference doSurveyReset(){
    setAllSurveys();
    return null;
  }

    private static TestMethod void testMakeNewSurvey(){
    SurveyTestingUtil tu = new SurveyTestingUtil();
    Apexpages.currentPage().getParameters().put('uId', Userinfo.getUserId());
    Apexpages.Standardcontroller stc;
    GSurveysController sc = new GSurveysController(stc);
    System.assert(sc.makeNewSurvey()==null);
    sc.surveySite = '--SELECT SITE--';
    sc.newSurveyName = 'TestMakeNewSurvey';
    //system.assert(sc.makeNewSurvey()==null);
    sc.surveySite = 'blah';
    System.assert(sc.makeNewSurvey()!=null);
    sc.doSurveyReset();     
  } 
   
   
    private static void testMakeRSSTemplate(){
    Apexpages.currentPage().getParameters().put('uId', Userinfo.getUserId());
    Apexpages.currentPage().getParameters().put('RecordType', [select id from RecordType where name = 'RSS Template' limit 1][0].id);
   
    Apexpages.Standardcontroller stc;
    GSurveysController sc = new GSurveysController(stc);
    System.assert(sc.makeNewSurvey()==null);
    sc.surveySite = '--SELECT SITE--';
    sc.newSurveyName = 'TestMakeNewRSSTemplate';
    //system.assert(sc.makeNewSurvey()==null);
    sc.surveySite = 'blah';
    System.assert(sc.makeNewSurvey()!=null);
    sc.doSurveyReset();     
   }
    
  
  static webservice String deleteSurvey(String deleteId){
    Survey__c s= [Select Id, Name from Survey__c where Id =:deleteId];
    delete s;
    
    return 'true';
  }
  
    private static TestMethod void testDeleteSurvey(){
    SurveyTestingUtil tu = new SurveyTestingUtil();
    Apexpages.currentPage().getParameters().put('uId', Userinfo.getUserId());
    Apexpages.Standardcontroller stc;
    GSurveysController sc = new GSurveysController(stc);
    System.assertEquals(GSurveysController.deleteSurvey(tu.surveyId),'true');
  }
  
  public Class miniSurvey{
    public String sName {get; set;}
    public String sId   {get; set;}
    
    public miniSurvey(String miniName, String miniId){
      sName = miniName;
      sId = miniId;
    } 
      
  }
}