/***
    OA_EmailBlast_AttachmentWrapper
    @author : Karteek Mekala <kmekala@akamai.com>; ALI KM <mohkhan@akamai.com>
    @Description : This is the Custom Controller for the OA_EmailBlast Page


    @History
    --Developer           --Date            --Change
    Ali KM               24/01/2011         Created this class.
                                            CR 920782 Email Blast - Order Approval object
                                            1. This is supporting Attachment Wrapper class for OA_EmailBlast_Controller.cls
    Ali KM               24/03/2011         CR 919117 e-Signature DocuSign implementation
                                            This class is also used by E-Signature Controller - OA_ESignIntermediateController
    Pranav Moktali       16/08/2013         CR 2327331: Adding Agreement object as one of the valid parentType

    Nagaraj Desai      14/12/2018      SFDC-3953 : Attachment Migration To Files
 */

public class OA_EmailBlast_AttachmentWrapper
{
        public Boolean checked { get; set;}
        //SFDC-3953
        public ContentDocumentLink attach { get; set; }
    	public Attachment attachRec { get; set; }
        public String parentType {get; set;}

        public ContentDocument doc { get; set; }
        public String DocName {get; set;}
        public Datetime DocLastModifiedDate {get; set;}
        public String createdBy {get; set;}
        public String fileType {get; set;}
        public String fileId {get; set;}

        //constructors - mutiple signatures
        public OA_EmailBlast_AttachmentWrapper()
        {
                //SFDC-3953
                attach = new ContentDocumentLink();
            	attachRec = new Attachment();
                checked = false;
        }
        public OA_EmailBlast_AttachmentWrapper(OA_EmailBlast_AttachmentWrapper oaWrapper)
        {
                attach = oaWrapper.attach;
                if(oaWrapper.attach.LinkedEntityId != null) {
                        String tempStr = String.valueOf(oaWrapper.attach.LinkedEntity.Type);
                        if(tempStr == 'Apttus__APTS_Agreement__c') {
                                parentType = 'Agreement';
                        }
                        else if(tempStr == 'Order_Approval__c') {
                                parentType = 'Order Approval';
                        }
                        else {
                                parentType = tempStr;
                        }
                }
                checked = false;
        }
        //SFDC-3953
        public OA_EmailBlast_AttachmentWrapper(ContentDocumentLink pAttachment)
        {
                attach = pAttachment;
                checked = false;
                if(pAttachment.LinkedEntityId != null) {
                        String tempStr = String.valueOf(pAttachment.LinkedEntity.Type);
                        if(tempStr == 'Apttus__APTS_Agreement__c') {
                                parentType = 'Agreement';
                        }
                        else if(tempStr == 'Order_Approval__c') {
                                parentType = 'Order Approval';
                        }
                        else {
                                parentType = tempStr;
                        }
                }

                fileId=pAttachment.ContentDocument.LatestPublishedVersionId;
                // check if attachment parent is Opportunity (006) or Order Approval (a0I)

                /*
                   if (tempStr.startsWith(Schema.Sobjecttype.Opportunity.getKeyPrefix()))
                    parentType = 'Opportunity';
                   else if (tempStr.startsWith(Schema.Sobjecttype.Order_Approval__c.getKeyPrefix()))
                    parentType = 'Order Approval';
                   else if (tempStr.startsWith(Schema.Sobjecttype.Apttus__APTS_Agreement__c.getKeyPrefix()))
                    parentType = 'Agreement';
                 */
        }

        public static String getObjType(String objId){
                String objType = '';
                if(objId.startsWith(Schema.Sobjecttype.Opportunity.getKeyPrefix()))
                        objType = 'Opportunity';
                else if(objId.startsWith(Schema.Sobjecttype.Order_Approval__c.getKeyPrefix()))
                        objType = 'Order Approval';
                return objType;
        }

        public static String getObjType(Id objId){
                return getObjType(String.valueOf(objId));
        }

        public OA_EmailBlast_AttachmentWrapper(ContentDocument conDoc,Map<Id,String> userInfoMap)
        {
                doc = conDoc;
                checked= false;
                DocName = conDoc.Title;
                createdBy = userInfoMap.get(conDoc.OwnerId);
                DocLastModifiedDate = conDoc.ContentModifiedDate;
                fileType = 'File';
                if(conDoc.ParentId != null )
                        parentType = getObjType(conDoc.ParentId);
                fileId = conDoc.Id;
                //parentType = Q2O_DocuSignUtilClass.getObjType(pAttachment.ParentId);
        }
        /*
           //test method
           public static testMethod void testMe() {

            OpportunityProductWrapper w1 = new OpportunityProductWrapper();
            System.assertEquals(w1.checked,false);
            OpportunityProductWrapper w2 = new OpportunityProductWrapper(new Product2(name='Test1'));
            System.assertEquals(w2.p.name,'Test1');
            System.assertEquals(w2.checked,false);
            OpportunityProductWrapper w3 = new OpportunityProductWrapper(true, new Product2(name='Test3'));
            System.assertEquals(w3.p.name,'Test3');
            System.assertEquals(w3.checked,true);
            OpportunityProductWrapper w4 = new OpportunityProductWrapper(w3);
            System.assertEquals(w4.p.name,'Test3');
            System.assertEquals(w4.checked, true);
           }
         */
}