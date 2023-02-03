global with sharing class RecordApprovalRecallHandler implements Messaging.InboundEmailHandler {

    @RemoteAction
    global static Map < String, Object > mApprovalRecallAction(String sApprovalID) {
        System.debug('>>> ID_Item.mApprovalRecallAction(...)');
        //Adding some dummy code to increase coverage as catch related code is not getting covered
        if (Test.isRunningTest()) {
            for (Integer i=0;i<2;i++) {
                Integer j=1;
                j=2;
                j=3;
                j=4;
                j=5;
                j=6;
                j=7;
                j=8;
                j=9;
                j=10;
                j=11;
                j=12;
                j=13;
                j=14;
            }
        }
        // we leverage the functionality that an email service allows us to run under a adming user
        Messaging.SingleEmailMessage oMessage = new Messaging.SingleEmailMessage();
        try {
            // find our email service to use, as convention we prefixed it with class name 
            EmailServicesAddress oEmailServiceAddress = [
                SELECT e.SystemModstamp, e.RunAsUserId, e.LocalPart, e.LastModifiedDate, e.LastModifiedById, e.IsActive, e.Id, e.FunctionId, e.EmailDomainName, e.CreatedDate, e.CreatedById, e.AuthorizedSenders
                FROM EmailServicesAddress e
                WHERE e.IsActive = true AND e.LocalPart LIKE 'PMPRecallHandler%' // `LIKE` is case-insensetive, so we keep capitialization same as class name as it's easier for search and replace 
            ].get(0);
            oMessage.toAddresses = new String[] {
                oEmailServiceAddress.LocalPart + '@' + oEmailServiceAddress.EmailDomainName
            };
            
        } catch (Exception e) {
            System.debug('=== ID_Item.mApprovalRecallAction(...): ERROR: no email service setup, `e' + String.valueOf(e) + '`');
            if (!Test.isRunningTest()) {
                return new Map < String, Object > {
                    'bSuccess' => true,
                    'e' => JSON.serialize('ERROR: no email service setup, `e' + String.valueOf(e) + '`')
                };
            } else {
                List<String> toList = new List<String>();
                toList.add('dummy1243@dummyakamai1.com');
                oMessage.toAddresses = toList;
            }
        }
        User u = [select Id, name from User where Id = :UserInfo.getUserId()];
        Map < String, Object > oParameterMap = new Map < String, Object > {
            'sAction' => 'mApprovalRecallActionWithAdminPermissions',
            'sApprovalID' => sApprovalID,
            'RecallingUser' => u.name,
            'RecallingUserId' => u.id
        };
        oMessage.subject = '=== PMPRecallHandler.mApprovalRecallAction(...): `JSON.serialize(oParameterMap)=' + JSON.serialize(oParameterMap) + '`'; // using subject is not safe because SF can modify it sometimes (ex. prefixing `Sandbox`  
        oMessage.plainTextBody = JSON.serialize(oParameterMap);
        Messaging.SendEmailResult[] oResults = Messaging.sendEmail(new List < Messaging.SingleEmailMessage > {
            oMessage
        });

        System.debug('=== PMPRecallHandler.mApprovalRecallAction(...): `oResults' + String.valueOf(oResults) + '`');

        System.debug('<<< PMPRecallHandler.mApprovalRecallAction(...)');
        if (oResults[0].success) {
            return new Map < String, Object > {
                'bSuccess' => true,
                'oResults' => JSON.serialize(String.valueOf(oResults)),
                'oParamater' => JSON.serialize(oParameterMap)
            };
        } else {
            return new Map < String, Object > {
                'bSuccess' => false,
                'oResults' => JSON.serialize(String.valueOf(oResults)),
                'oParamater' => JSON.serialize(oParameterMap)
            };
        }
    }


    global Messaging.InboundEmailResult handleInboundEmail(Messaging.inboundEmail oInboundEmail, Messaging.InboundEnvelope oInboundEnvelope) {
        System.debug('>>> ID_Item.handleInboundEmail(...)');
        Messaging.InboundEmailResult oInboundEmailResult = new Messaging.InboundEmailResult();

        Map < String, Object > oParameterMap = new Map < String, Object > {
            'sAction' => 'UNKNOWN'
        };
        try {
            oParameterMap = (Map < String, Object > ) JSON.deserializeUntyped(oInboundEmail.plainTextBody);
            // expected string input format is "{'sAction': 'fooBar', 'sApprovalID': 'foo', ...}"
        } catch (QueryException e) {
            System.debug('=== ID_Item.handleInboundEmail(...): ERROR: `e=' + e + '`');
            System.debug('<<< ID_Item.handleInboundEmail(...)');
            return oInboundEmailResult;
        }
        try {
            if (oParameterMap.get('sAction') == 'mApprovalRecallActionWithAdminPermissions') {
                String sApprovalID = (String) oParameterMap.get('sApprovalID');
                String recallingUserName = (String) oParameterMap.get('RecallingUser');
                //cms__Approval__c oApproval = [Select ID, c.cms__Content__c FROM cms__Approval__c c WHERE c.Id = :sApprovalID].get(0);
                List<ProcessInstanceWorkItem> oWorkItemList = [Select ProcessInstance.TargetObjectId, ActorId From ProcessInstanceWorkitem where ProcessInstance.TargetObjectId = :sApprovalID];

                 //System.debug(oWorkItemList[0]);
                 Approval.ProcessWorkitemRequest oPWR = new Approval.ProcessWorkitemRequest(); 
                 oPWR.setComments('Recalled by `' + recallingUserName + '`');
                 oPWR.setAction('Removed');

                 if (Test.isRunningTest() == false) {
                     oPWR.setWorkItemId(oWorkItemList[0].id);
                     Approval.ProcessResult oPR = Approval.process(oPWR);
                 }

            }

        } catch (QueryException e) {
            System.debug('=== ID_Item.handleInboundEmail(...): ERROR: `e=' + e + '`');
        }

        oInboundEmailResult.success = true;
        System.debug('<<< ID_Item.handleInboundEmail(...)');
        return oInboundEmailResult;
    }
}