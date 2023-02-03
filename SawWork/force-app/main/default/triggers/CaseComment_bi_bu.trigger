/**
    CR 2068273 - Invoice Review Cases Process migration from Siebel to SF.
    Trigger on Case Comment for Invoice Review RecType to ensure: 
        - Case Comments are always Public
        - Validation to ensure Case Comments are not made Private by anybody.
        
    Lisha Murthy          11/11/2013        CR 2411301 - Need to disable trigger code for Service Cloud
                                            - By-passing the trigger code for connection user.        
*/   
trigger CaseComment_bi_bu on CaseComment (before insert, before update)
{ 
    if(!UserInfo.getName().equalsIgnoreCase('Connection User'))
    {
        for (CaseComment cc : Trigger.new)
        {
            if (Trigger.isInsert)
                cc.isPublished=true;
        
            if (Trigger.isUpdate && cc.isPublished==false && cc.isPublished != Trigger.oldMap.get(cc.Id).isPublished)
            {
                cc.addError('Insufficient access.');
            }
        }
    }
}