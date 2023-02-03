public with sharing class JiveContentFilterWrapper  {

    public String filterText  ;
    public String filterAuthor ;
    public String filterDate  ;
    public String jiveURL;
    public Boolean filterGroup; //group is a keyword
    public Boolean filterBlog;
    public Boolean filterDocument;
    public Boolean filterSpace;
    public String filterTypeOFDiscussion;
  
   public  JiveContentFilterWrapper(String filterText,String filterAuthor,String filterDate,String jiveUrl,Boolean filterGroup ,Boolean filterBlog,Boolean filterDocument,Boolean filterSpace,String filterTypeOFDiscussion){
        this.filterText = filterText;
        this.filterAuthor = filterAuthor ;
        this.filterDate=filterDate;
        this.jiveURL = jiveUrl; 
        this.filterGroup = filterGroup ;
        this.filterBlog=filterBlog  ;
        this.filterDocument=filterDocument;
        this.filterSpace=filterSpace;
        this.filterTypeOFDiscussion=filterTypeOFDiscussion;
    }


}





/*public with sharing class JiveContentFilterWrapper {

    public String filterText  ;
    public String filterAuthor ;
    public String filterDate  ;
    public String jiveURL;
    public Boolean filterGroup; //group is a keyword
    public Boolean filterBlog;
    public Boolean filterDocument;
    public Boolean filterSpace;
    public Boolean filterQuestion;
    public Boolean filterQuestionWithAnswer;
    public String filterTypeOFDiscussion;
    //queWithAns
    //public static void sendContentFilters(String filterText,String filterDate,String filterAuthor,Boolean grp,Boolean blog,Boolean document,Boolean space,Boolean question){
    
   // public JiveContentFilterWrapper(String filterText,String filterAuthor,String filterDate,String jiveUrl,Boolean filterGroup ,Boolean filterBlog,Boolean filterDocument,Boolean filterSpace,Boolean filterQuestion,Boolean filterQuestionWithAnswer){
   
   //uncomment this
//   public JiveContentFilterWrapper(String filterText,String filterAuthor,String filterDate,String jiveUrl,Boolean filterGroup ,Boolean filterBlog,Boolean filterDocument,Boolean filterSpace,String filterTypeOFDiscussion){
    
    
    public JiveContentFilterWrapper(String filterText,String filterAuthor,String filterDate,String jiveUrl,Boolean filterGroup ,Boolean filterBlog,Boolean filterDocument,Boolean filterSpace,Boolean filterQuestion){
    
        this.filterText = filterText;
        this.filterAuthor = filterAuthor ;
        this.filterDate=filterDate;
        this.jiveURL = jiveUrl; 
        this.filterGroup = filterGroup ;
        this.filterBlog=filterBlog  ;
        this.filterDocument=filterDocument;
        this.filterSpace=filterSpace;
        this.filterQuestion=filterQuestion;
     // this.filterQuestionWithAnswer=filterQuestionWithAnswer;
    //    this.filterTypeOFDiscussion=filterTypeOFDiscussion;
    }


}*/