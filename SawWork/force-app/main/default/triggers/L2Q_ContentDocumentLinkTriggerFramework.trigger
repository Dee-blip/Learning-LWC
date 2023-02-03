trigger L2Q_ContentDocumentLinkTriggerFramework on ContentDocumentLink (after delete, after insert, after undelete, after update, before delete, before insert, before update) {
    ApexTriggerHandlerAbstractClass.createHandler('ContentDocumentLink');
}