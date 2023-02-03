public class SF1_AdvAccExtension {

    //Boolean for SF1 Create Page Render
    public boolean SF1CreateAcc{get;set;}


    //CONSTRUCTOR
    public SF1_AdvAccExtension(ApexPages.StandardController controller) {
        SF1CreateAcc=false;
    }

    public void showCreateAccForSF1(){
        SF1CreateAcc=true;
    }
    public void hideCreateAccForSF1(){
        SF1CreateAcc=false;
    }
}