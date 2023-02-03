/*******************************************************************************************************
Name         :   SC_FeedCommentTrigger
Author       :   jrathod
Created Date :   Dec 23,2021
JIRA         :   ESESP-4062
Description  :  FeedComment trigger
********************************************************************************************************
Jay               23-Dec-2021       ESESP-4062    Initial version
*/

trigger SC_FeedCommentTrigger on FeedComment (after insert, after update) {

    SC_FeedCommentTriggerHandler handler = new SC_FeedCommentTriggerHandler();
    handler.process();

}