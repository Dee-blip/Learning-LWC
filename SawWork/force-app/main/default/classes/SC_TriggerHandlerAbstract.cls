/****************************************************************************
* Class name          :   SC_TriggerHandlerAbstract.cls
* Author              :   Vishnu Vardhan
* Created             :   20-August-2020 
* Purpose             :   TRF Trigger Handler
* Test Class          :   
*****************************************************************************

DATE             DEVELOPER        CR              DESCRIPTION
===========      =========        =======         ===========
Aug 20, 2020     Vishnu Vardhan   ESESP-2826      Trigger Handler Abstract Class
*****************************************************************************/
public with sharing abstract class SC_TriggerHandlerAbstract {
    
    public void process() {
        if(this.triggerCheck() == false) {
            return;
        }

        if(Trigger.isBefore && Trigger.isInsert) {
            this.handleBeforeInsert();
        }

        if(Trigger.isAfter && Trigger.isInsert) {
            this.handleAfterInsert();
        }

        if(Trigger.isBefore && Trigger.isUpdate) {
            this.handleBeforeUpdate();
        }

        if(Trigger.isAfter && Trigger.isUpdate) {
            this.handleAfterUpdate();
        }

        if(Trigger.isBefore && Trigger.isDelete) {
            this.handleBeforeDelete();
        }

        if(Trigger.isAfter && Trigger.isDelete) {
            this.handleAfterDelete();
        }

        if(Trigger.isAfter && Trigger.isUndelete) {
            this.handleAfterUndelete();
        }
    }   
    public virtual Boolean triggerCheck() {
        return true;
    }

    public virtual void handleBeforeInsert() {
        return;
    }
    public virtual void handleAfterInsert() {
        return;
    }
    
    public virtual void handleBeforeUpdate() {
        return;
    }
    public virtual void handleAfterUpdate() {
        return;
    }
    public virtual void handleBeforeDelete() {
        return;
    }
    public virtual void handleAfterDelete() {
        return;
    }
    public virtual void handleAfterUndelete() {
        return;
    }


}