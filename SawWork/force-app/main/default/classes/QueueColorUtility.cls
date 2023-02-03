/*****************************************************************************
 * Name             : QueueColorUtility
 * Created By       : Pitamber Sharma
 * Created Date     : 14-June-2013
 * Purpose          : Utility class to assign appropriate color to Queues to display on Service Cloude Home page. 
 DATE             DEVELOPER       CR            DESCRIPTION                               
 ===========      =========       =======       =========== 
 12-May-2014      Himanshu Kar    2578737(3.42) Assign the color coding for CC_SSL_QUEUE,CC_MEDIA_QUEUE,CC_WEBEXP_QUEUE,
                                CC Orphan Queue.
 05/22/2014       Kunal Sharma    2614926       Added logic for new EPE queue.   
 07/24/2014       Akhila Vidapanapati    Renamed
                     CC_T2_SITE_QUEUE --> CC_ER_WEBEXP_QUEUE
                     CC_T2_LUNA_QUEUE --> CC_ER_LUNA_QUEUE
                     CC_T2_DM_QUEUE   --> CC_ER_MEDIA_QUEUE  
 01/09/16         Pinkesh Rathore   3528581     Update CCare queue label prefixes from CC to ATS (Akamai Technical Support)    
 17/10/18         Vamsee S          ESESP-1650  Renamed
                     ATS_WEBEXP_QUEUE --> ATS_WEB_QUEUE
                     ATS_ER_WEBEX_QUEUE --> ATS_ER_WEB_QUEUE
 *****************************************************************************/

public with sharing class QueueColorUtility {
    public static void assignColorToCaseQueue(Map<String, List<String>> queuesMap, 
                                                                                Map<String, List<Case>> queueCaseMap) {
        Integer cnt15Mnt, cnt45Mnt, cnt4Hrs, cnt6Hrs, cnt12Hrs, cnt18Hrs, sev1Case;
        
        for(String qName : queueCaseMap.keySet()) {
        
            // Initializing all count variables for violation
            cnt15Mnt = 0; cnt45Mnt = 0; cnt4Hrs = 0; cnt6Hrs = 0; cnt12Hrs = 0; cnt18Hrs = 0; sev1Case = 0;
            
            for(Case cs : queueCaseMap.get(qName)) {
                if(cs.SLA_Violation_15min__c) {
                    cnt15Mnt++;
                }
                if(cs.SLA_Violation_45min__c) {
                    cnt45Mnt++;
                }
                if(cs.SLA_Violation_4h__c) {
                    cnt4Hrs++;
                }
                if(cs.SLA_Violation_6h__c) {
                    cnt6Hrs++;
                }
                if(cs.IR_Violavtion_12h__c) {
                    cnt12Hrs++;
                }
                if(cs.IR_Violavtion_18h__c) {
                    cnt18Hrs++;
                }
                if(cs.Severity__c != null && cs.Severity__c.equals('1')) {
                    sev1Case++;
                }
            }
            System.debug('@@@@ ' + qName + ', ' + cnt15Mnt + ', ' + cnt45Mnt);
            if(qName.equalsIgnoreCase('STBE Media Queue') || qName.equalsIgnoreCase('STBE Web Experience Queue') 
                    || qName.equalsIgnoreCase('STBE Assign Me Queue')
                    || qName.equalsIgnoreCase('Technical Support Product Queue 1-8') 
                    || qName.equalsIgnoreCase('ATS_LUNA_QUEUE')
                    || qName.equalsIgnoreCase('ATS_MEDIA_QUEUE')
                    || qName.equalsIgnoreCase('ATS_WEB_QUEUE')
                    || qName.equalsIgnoreCase('ATS_Orphan_Queue')
                    || qName.equalsIgnoreCase('ENG Emerging Products Queue')
                  || qName.equalsIgnoreCase('CPD OCDN Queue')) {
                queuesMap.get(qName).remove(3);
                if(cnt15Mnt > 0) {
                    queuesMap.get(qName).add(3, '   #FF5C5C');
                } else if(cnt45Mnt > 0) {
                    queuesMap.get(qName).add(3, 'yellow');
                } else {
                    queuesMap.get(qName).add(3, '#B2EC5D');
                }
            } else if(qName.equalsIgnoreCase('AMG EMEA Queue')
                                || qName.equalsIgnoreCase('AMG APJ Queue')
                                || qName.equalsIgnoreCase('AMG NA Queue')
                                || qName.equalsIgnoreCase('AMG Standard EMEA Queue')
                                || qName.equalsIgnoreCase('AMG Priority/Premium EMEA Queue')
                                || qName.equalsIgnoreCase('AMG Standard APJ Queue')
                                || qName.equalsIgnoreCase('AMG Priority/Premium APJ Queue')
                                || qName.equalsIgnoreCase('AMG Standard NA Queue')
                                || qName.equalsIgnoreCase('AMG Priority/Premium NA Queue')
                                || qName.equalsIgnoreCase('AMG ECG Queue')
                                || qName.equalsIgnoreCase('AMG Manager Queue')
                                || qName.equalsIgnoreCase('AMG APJ Hotseat Queue')
                                || qName.equalsIgnoreCase('AMG EMEA Hotseat Queue')
                                || qName.equalsIgnoreCase('AMG NA Hotseat Queue')
                                || qName.equalsIgnoreCase('AMG APJ Management Queue')
                                || qName.equalsIgnoreCase('AMG EMEA Management Queue')
                                || qName.equalsIgnoreCase('AMG NA Management Queue')) {
                queuesMap.get(qName).remove(3);
                if(cnt6Hrs >= 2) {
                    queuesMap.get(qName).add(3, '   #FF5C5C');
                } else if(cnt6Hrs > 0) {
                    queuesMap.get(qName).add(3, 'yellow');
                } else {
                    queuesMap.get(qName).add(3, '#B2EC5D');
                }
            } else if(qName.equalsIgnoreCase('AMG Orphan Queue')) {
                queuesMap.get(qName).remove(3);
                if(sev1Case > 0 || cnt6Hrs >= 2) {
                    queuesMap.get(qName).add(3, '   #FF5C5C');
                } else if(cnt6Hrs > 0) {
                    queuesMap.get(qName).add(3, 'yellow');
                } else {
                    queuesMap.get(qName).add(3, '#B2EC5D');
                }                   
            } else if(qName.equalsIgnoreCase('Billing Queue')) {
                queuesMap.get(qName).remove(3);
                if(cnt12Hrs > 0) {
                    queuesMap.get(qName).add(3, '   #FF5C5C');
                } else if(cnt18Hrs > 0) {
                    queuesMap.get(qName).add(3, 'yellow');
                } else {
                    queuesMap.get(qName).add(3, '#B2EC5D');
                }
            }
            
        }
        
    }
    
    public static void assignColorToERQueue(Map<String, List<String>> queuesMap, 
                                                                                Map<String, List<Engagement_Request__c>> queueERMap) {
        Integer age3Hrs, age1_3Hrs, age3andMoreHrs, requestCnt, age;
        for(String qName : queuesMap.keySet()) {
            age3Hrs = 0; age1_3Hrs = 0; age3andMoreHrs = 0; requestCnt = 0;
            for(Engagement_Request__c er : queueERMap.get(qName)) {
                age = (Integer)((System.now().getTime() - er.CreatedDate.getTime()) / (1000 * 60 * 60));
                System.debug(' ER ID : ' + er.Id + ' Age : ' + age);
                if(age > 3) {
                    age3Hrs++;
                    age3andMoreHrs++;
                } else if(age == 3) {
                    age3andMoreHrs++;
                    age1_3Hrs++;
                }else if(age >= 1) {
                    age1_3Hrs++;
                } else {
                    requestCnt++;
                }
            }
            System.debug('Qname : ' + qName + ' ' + age3Hrs + ' ' + age1_3Hrs );
            if(qName.equalsIgnoreCase('STBE Media Engagement Queue')
                                || qName.equalsIgnoreCase('STBE Web Experience Engagement Queue')) {
                queuesMap.get(qName).remove(3);
                if(age3Hrs > 0) {
                    queuesMap.get(qName).add(3, '   #FF5C5C');
                } else if(age1_3Hrs > 0) {
                    queuesMap.get(qName).add(3, 'yellow');
                } else {
                    queuesMap.get(qName).add(3, '#B2EC5D');
                }
            } else if(qName.equalsIgnoreCase('T2 Product Engagement Queue 1-8')
                                    || qName.equalsIgnoreCase('ATS_ER_MEDIA_QUEUE')
                                    || qName.equalsIgnoreCase('ATS_ER_LUNA_QUEUE')
                                    || qName.equalsIgnoreCase('ATS_ER_WEB_QUEUE')) {
                queuesMap.get(qName).remove(3);
                if(age3andMoreHrs > 0) {
                    queuesMap.get(qName).add(3, '   #FF5C5C');
                } else if(age1_3Hrs > 0) {
                    queuesMap.get(qName).add(3, 'yellow');
                } else {
                    queuesMap.get(qName).add(3, '#B2EC5D');
                }
            }
        }
    }
}