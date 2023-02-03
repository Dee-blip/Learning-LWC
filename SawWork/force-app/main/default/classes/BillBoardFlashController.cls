/*

   This is the only class. All other billboard classes are deprecated 
 */

global class BillBoardFlashController 
{

    public static Billboard_Alert_Rule__c bill_ar {get;set;}
    public static String message {get;set;} 
    public static Boolean inPreviewMode {get;set;}

    /*class to check for the record with condition(common for both BillboardControl  and condition methods) :
      Alert_Type = 'Homepage'
      isActive__c = true 
      Alert_End_Date__c >= TODAY AND 
      Alert_Start_Date__c <= TODAY

      returns the Billboard_Alert_Rule object if the condition is satisfied else null */


    public static Billboard_Alert_Rule__c InitBillboard()
    {
        System.Debug('AGH in InitBillboard');
        Id selectedBillboardAlertId = ApexPages.currentPage().getParameters().get('id');
        if(String.isBlank(selectedBillboardAlertId))
        {
            inPreviewMode = false;
            for(Billboard_Alert_Rule__c  b:[SELECT Message__c,Id,Name, Alert_Type__c,URL_Frame_Height__c, URL_Frame_Width__c,URL_Frame_Width_Unit__c, URL_Frame_Height_Unit__c FROM Billboard_Alert_Rule__c where Alert_Type__c='BillBoard' AND isActive__c = true AND Alert_End_Date__c >= TODAY AND Alert_Start_Date__c <= TODAY])
            {
                String BBalertAssociatedUser = b.ID+UserInfo.getUserId();
                System.debug('BBalertAssociatedUser'+BBalertAssociatedUser);
                if(Billboard_User_Custom_Settings__c.getInstance(BBalertAssociatedUser) == null)
                {
                    System.debug('BBalertAssociatedUser'+Billboard_User_Custom_Settings__c.getInstance(BBalertAssociatedUser));
                    return b;
                }
            }
        }
        else
        {
            inPreviewMode = true;
            return [SELECT Message__c,Id,Name, Alert_Type__c,URL_Frame_Height__c, URL_Frame_Width__c,URL_Frame_Width_Unit__c, URL_Frame_Height_Unit__c FROM Billboard_Alert_Rule__c where Id=:selectedBillboardAlertId];
        }
        return null;
    }

    /* fetches the record returned by InitBillboard and returns the frame height,width,and the dimensions */
    webService static String BillboardControl () 
    {   
        Billboard_Alert_Rule__c bAlertRule=null;
        bAlertRule=InitBillboard();
        if(bAlertRule!=null)
            return bAlertRule.URL_Frame_Height__c+':'+bAlertRule.URL_Frame_Height_Unit__c+':'+bAlertRule.URL_Frame_Width__c+':'+bAlertRule.URL_Frame_Width_Unit__c;
        else
            return '';

    }

    public BillBoardFlashController()
    {
        bill_ar = new Billboard_Alert_Rule__c();
        message = null;
        inPreviewMode = false;
        System.Debug('AGH in constructor' + inPreviewMode);
    }




    public static PageReference continueNonPreviewMode()
    {
        System.debug('AGH in continueNonPreviewMode');
        condition();
        Billboard_User_Custom_Settings__c  rule = new Billboard_User_Custom_Settings__c ();
        // TODO - WHY IS WAS IT CHANGED TO THIS? THIS CREATES A LOT OF CONFUSION. WHY ARE WE NOT USING
        // THE BILLBOARD ALERT ID FIELD AT ALL? 
        rule.Name = bill_ar.ID+UserInfo.getUserId();
        //rule.Billboard_Alert_Id__c =Billboard_Alert_Rule__c;
        rule.Last_Seen_Date__c = System.Now();
        insert rule;
        PageReference ref = new PageReference('/home/home.jsp');
        return ref;
    }

    public static PageReference continuePreviewMode()
    {
        return null;
    }



    public static PageReference condition()
    {

        Billboard_Alert_Rule__c bAlertRule=null;
        bAlertRule=InitBillboard();
        if(bAlertRule!=null)
        { 
            bill_ar = bAlertRule;
            message = bAlertRule.Message__c;
            return null;
        } 
        else
        {
            //Return the page 
            PageReference ref = new PageReference('/home/home.jsp');
            return ref;
        }
    }

    public static String getPartnerBillboardText()
    {
        String billboardText = '';
        for(Billboard_Alert_Rule__c bar : [SELECT  Message__c FROM Billboard_Alert_Rule__c where Alert_Type__c='Partner Welcome Page Alert' AND isActive__c = true AND Start_Time__c <= :DateTime.now() AND End_Time__c > :DateTime.now() order by createddate desc limit 1])
        {
            billboardText = bar.Message__c;
        }
        return billboardText;
    }

}