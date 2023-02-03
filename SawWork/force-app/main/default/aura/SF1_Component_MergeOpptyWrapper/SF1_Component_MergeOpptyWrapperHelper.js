({
  initHelper : function(component, event, helper) {
   component.set('v.errormessage', '');
   component.set('v.successMessage', '');
   component.set('v.dupeError', false);
     var oppId = component.get('v.recordId');
     var action1 = component.get('c.getOpportunityRecord');

      action1.setParams({
                  "oppId": oppId,

                 });
      action1.setCallback(this, function(response) {
      var state = response.getState();
      
      if (state === 'SUCCESS') {
        var oppRecord = response.getReturnValue();
        
     
      if(oppRecord.RecordType.Name == "AWE Opportunities")
      {
            

            this.navigateToPageIfLightning(component,'Migrateoppty', oppRecord.Id, oppRecord.Name);
            

          var action2 = component.get('c.getListOfAQLOpportunities');
        action2.setParams({
                  "oppName": oppRecord.Name,

                 });
          action2.setCallback(this, function(response) {
          var state = response.getState();
      
          if (state === 'SUCCESS') {
            var listOfOpps = response.getReturnValue();
            if(this.evalauteForDupeError(listOfOpps, true))
            {
              var action4 = component.get('c.getDuplicateOpportunityError');
              action4.setCallback(this, function(response) {
              var state = response.getState();
      
              if (state === 'SUCCESS') 
              {
                var msg =  response.getReturnValue();
                component.set('v.errormessage', msg+' . Click Cancel to go Back to Opportunity');
            component.set('v.isPrimaryFlow', true);
            component.set('v.dupeError', true);
              }
              
      
            });
              $A.enqueueAction(action4);
            }
            else
            {
              listOfOpps = helper.getContactNameList(listOfOpps, true);
              component.set('v.listOfOpportunitiesPrimary', listOfOpps);
              component.set('v.listOfOpportunitiesSecondary', listOfOpps);
                  component.set('v.isPrimaryFlow', true);
              }
        
       
      }
    });
      $A.enqueueAction(action2);
      }
      else if(oppRecord.RecordType.Name == "Akamai Opportunity")
      {

            this.navigateToPageIfLightning(component, 'MigrateopptyExisting', oppRecord.Id, oppRecord.Name);
     

          var action3 = component.get('c.getListOfOpportunities');
        action3.setParams({
                  "accId": oppRecord.AccountId,

                 });
          action3.setCallback(this, function(response) {
          var state = response.getState();
      
          if (state === 'SUCCESS') {
            var listOfOpps = response.getReturnValue();
            if(this.evalauteForDupeError(listOfOpps, false))
            {
          
              var action4 = component.get('c.getDuplicateOpportunityError');
              action4.setCallback(this, function(response) {
              var state = response.getState();
      
              if (state === 'SUCCESS') 
              {
                var msg =  response.getReturnValue();
                component.set('v.errormessage', msg+' . Click Cancel to go Back to Opportunity');
            component.set('v.isPrimaryFlow', true);
            component.set('v.dupeError', true);
              }
              
      
            });
              $A.enqueueAction(action4);

            }
            else
            {
              listOfOpps = helper.getContactNameList(listOfOpps,false);
              component.set('v.listOfOpportunitiesSecondary', listOfOpps);
              oppRecord = helper.getContactName(oppRecord);
              component.set('v.selectedPrimaryOpportunity', oppRecord);
              component.set('v.isPrimaryFlow', false);
            }

            
        
       
      }
    });
      $A.enqueueAction(action3);

      }

      component.set('v.displayBackButton', false);
      component.set('v.uncheckBoxes', false);
      component.set('v.selectedPrimaryOpportunityPlaceholder', null);

       
      }
    });
      $A.enqueueAction(action1);


       
  },
  getContactName : function(opp) {



          var contactList = opp.OpportunityContactRoles;
          
          if(contactList ==null || contactList.length == 0)
          {
            opp.ContactName = "[None]";
          }
          else if(contactList.length == 1)
          {
            opp.ContactName = contactList[0].Contact.Name;
          }
          else            
          {
            opp.ContactName = "[Multiple]";
          }

      
        return opp;
  },
    getContactNameList : function(listOfOpps, isAWEFlow) {
   var newListOfOpps = new Array();
     for(var i=0;i<listOfOpps.length;i++)
        {
          var opp = listOfOpps[i];
            
      if(isAWEFlow)
            {
                opp = this.getContactName(opp);
                newListOfOpps.push(opp);
            }
            else if(this.getContactName(opp).ContactName != "[None]")
            {
                opp = this.getContactName(opp);
                newListOfOpps.push(opp)
            }
          

        }
        return newListOfOpps;
  },
  uncheckAllOtherCheckBox : function(component, event, helper, eachOppId, listOfOpps)
  {
    component.set("v.uncheckBoxes",false);
    event.target.checked = true;
  },
   
  navigateToPageIfLightning : function(component,fromButton,oppId,oppName)
  {
    var action = component.get("c.isLightning");
        action.setCallback(this, function(a) {
            
            if(a.getReturnValue() == true)
            {

                var urlEvent = $A.get("e.force:navigateToURL");
          urlEvent.setParams({
              "url": "/one/one.app#/alohaRedirect/apex/MigrateOpptyPage?fromButton="+fromButton+"&recordId="+oppId+"&recordName="+oppName
          });
          urlEvent.fire();
            }
            else
            {
              component.set('v.isLightning', false);
            }
        });
        $A.enqueueAction(action);
  },
    evalauteForDupeError: function(listOfOpps, isAWE)
    {
        var nonNonContactRoleOppCount = 0;
        for(var i=0;i<listOfOpps.length;i++)
        {
          var opp = listOfOpps[i];
      var contactList = opp.OpportunityContactRoles;   
          if(contactList !=null && contactList.length != 0)
          {
            nonNonContactRoleOppCount ++;
          }
           
        }
        if(isAWE)
            {
                if(nonNonContactRoleOppCount < 2)
                    return true
                else
                    return false;
            }
            else
            {
                if(nonNonContactRoleOppCount < 1)
                    return true
                else
                    return false;
            }
    }
})