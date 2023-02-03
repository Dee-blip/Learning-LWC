public class JiveMessageWrapper {

        public String contentID;
        public Boolean isAnswer;
        public String replyComments;
        public String jiveURL;
    

   
    public JiveMessageWrapper(String jiveUrl,Boolean optionReply,String contentId,String caseComment){
  
        this.contentID = contentId;
        this.isAnswer= optionReply;
        this.replyComments= caseComment;
        this.jiveURL = jiveUrl;

    }
        
}