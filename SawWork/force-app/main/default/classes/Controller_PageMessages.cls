public with sharing class Controller_PageMessages {
 
    public String CustomPageMessages_ClosableErrorsRenderPlaceHolder {
        get {
        if(CustomPageMessages_ClosableErrorsRenderPlaceHolder == null) CustomPageMessages_ClosableErrorsRenderPlaceHolder = '';
        return CustomPageMessages_ClosableErrorsRenderPlaceHolder;
        }
        private set;
    }
     
    public List<PageMessages.PageMessage> getPageMessages() {
        return PageMessages.getMessages();
    }
}