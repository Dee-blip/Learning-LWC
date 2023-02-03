/****************************************************************************
* Class name          :   SC_FeedItemDeleteTrigger.cls
* Author              :   Vishnu Vardhan
* Created             :   03-Aug-2020
* Purpose             :   To enforce validations on FeedItem delete 
* Test Class          :   
-------------------------------------------------------------------------------
DATE             DEVELOPER        CR              DESCRIPTION
===========      =========        =======         ===========
03-Aug-2020      Vishnu Vardhan   ESESP-2826      PST Case TextPosts Can't be deleted
*****************************************************************************/
trigger SC_FeedItemDeleteTrigger on FeedItem (before delete) {
    SC_TriggerHandlerAbstract feedTriggerHandler = new SC_FeedItemTriggerHandler(); 
    feedTriggerHandler.process();
}