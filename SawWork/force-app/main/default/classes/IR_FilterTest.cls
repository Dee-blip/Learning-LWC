/**
 * This class contains unit tests for validating the behavior of Apex classes
 * and triggers.
 *
 * Unit tests are class methods that verify whether a particular piece
 * of code is working properly. Unit test methods take no arguments,
 * commit no data to the database, and are flagged with the testMethod
 * keyword in the method definition.
 *
 * All test methods in an organization are executed whenever Apex code is deployed
 * to a production organization to confirm correctness, ensure code
 * coverage, and prevent regressions. All Apex classes are
 * required to have at least 75% code coverage in order to be deployed
 * to a production organization. In addition, all triggers must have some code coverage.
 * 
 * The @isTest class annotation indicates this class only contains test
 * methods. Classes defined with the @isTest annotation do not count against
 * the organization size limit for all Apex scripts.
 *
 * See the Apex Language Reference for more information about Testing and Code Coverage.
 */
@isTest
public class IR_FilterTest
{
static testMethod void Filter_PositiveTest(){
IR_PageControllerBase pg = new IR_PageControllerBase();
IR_Filter filter = new IR_Filter();

filter.pageController=pg;
filter.inputQuery='select Name, Id, AKAM_Account_ID__c, OwnerId, CreatedDate, Area_Rank__c from Account' ;
filter.ReRenderIds='label';
filter.LimitSOQL=500;
filter.Status='status';
filter.DefaultOrderBy='Name';
filter.DefaultSortOrderDirection='Desc';
IR_FilterObject fieldset = new IR_FilterObject();
fieldset.AddField('string','Name','Name');
fieldset.AddField('Id','Id','Id');
fieldset.AddField('string','Account Id','AKAM_Account_ID__c');
fieldset.AddField('Date','Created Date','CreatedDate');
fieldset.AddField('Integer','Area Rank','Area_Rank__c');

filter.fieldSet = fieldset;

filter.getInit();

filter.listOfFields[0].TextboxValue='abc*';
filter.listOfFields[2].TextboxValue='*AC*';
filter.listOfFields[4].TextboxValue='1';
filter.listOfFields[3].DateBoxa='9/12/2012';
filter.listOfFields[3].DateBoxb='';

filter.ApplyFilter();
String OutputQuery = filter.OutputQuery;
string expectedOutput ='select Name, Id, AKAM_Account_ID__c, OwnerId, CreatedDate, Area_Rank__c from Account where Name Like \'abc%\' and AKAM_Account_ID__c Like \'%ac%\' and CreatedDate > 2012-09-12T00:00:00Z and Area_Rank__c = \'1\' Order by Name Desc limit 500';


String [] autoList = new String[]{'a','b','c','d','e','f','g','h','i'};
fieldset = new IR_FilterObject();
fieldset.AddField('string','Name','Name','False',autoList);
fieldset.AddField('Id','Id','Id','False',autoList);
fieldset.AddField('string','Account Id','AKAM_Account_ID__c','False',autoList);
fieldset.AddField('Date','Created Date','CreatedDate','False',autoList);
fieldset.AddField('DateTime','Created Date','CreatedDate','False',autoList);
fieldset.AddField('Integer','Area Rank','Area_Rank__c','False',autoList);
filter.fieldSet = fieldset;

filter.ClearFilter();
filter.inputQuery='select Name, Id, AKAM_Account_ID__c, OwnerId, CreatedDate, Area_Rank__c from Account where Name != \'abc\'' ;
filter.listOfFields[0].TextboxValue='*abc*';
filter.listOfFields[2].TextboxValue='*AC';
filter.listOfFields[4].TextboxValue='1';
filter.listOfFields[3].DateBoxa='9/12/2012';
filter.listOfFields[3].DateBoxb='10/12/2012';

filter.ApplyFilter();
OutputQuery = filter.OutputQuery;
expectedOutput ='select Name, Id, AKAM_Account_ID__c, OwnerId, CreatedDate, Area_Rank__c from Account where Name != \'abc\' and Name Like \'%abc%\' and AKAM_Account_ID__c Like \'%ac\' and CreatedDate > 2012-09-12T00:00:00Z and CreatedDate < 2012-10-12T00:00:00Z and Area_Rank__c = \'1\' Order by Name Desc limit 500';


fieldset = new IR_FilterObject();
fieldset.AddField('Integer','Area Rank','Area_Rank__c','True');
fieldset.AddField('string','Name','Name','True');
fieldset.AddField('Id','Id','Id','True');
fieldset.AddField('Date','Created Date','CreatedDate','True');
fieldset.AddField('DateTime','Created Date','CreatedDate','True');
fieldset.AddField('string','Account Id','AKAM_Account_ID__c','True');
filter.fieldSet = fieldset;


filter.ClearFilter();
filter.inputQuery='select Name, Id, AKAM_Account_ID__c, OwnerId, CreatedDate, Area_Rank__c from Account' ;
filter.listOfFields[4].TextboxValue='*abc*';
filter.listOfFields[2].TextboxValue='*AC';
filter.listOfFields[0].TextboxValue='1';
filter.listOfFields[3].DateBoxa='9/12/2012';
filter.listOfFields[3].DateBoxb='10/12/2012';


filter.ApplyFilter();
OutputQuery = filter.OutputQuery;
System.debug(OutputQuery);

filter.listOfFields[4].TextboxValue='abc or rat or *a or a* or *a* or <>cd';
filter.listOfFields[2].TextboxValue='<>abc and <>rat and *a and a* and *af*';
filter.listOfFields[0].TextboxValue='1';

filter.ApplyFilter();
OutputQuery = filter.OutputQuery;
System.debug(OutputQuery);
//expectedOutput ='select Name, Id, AKAM_Account_ID__c, OwnerId, CreatedDate, Area_Rank__c from Account where Area_Rank__c = \'1\' and Name Like \'%abc%\' and AKAM_Account_ID__c Like \'%ac\' and CreatedDate > 2012-09-12T00:00:00Z and CreatedDate < 2012-10-12T00:00:00Z and  Order by Name Desc limit 500';
//System.AssertEquals(OutputQuery,expectedOutput);


fieldset = new IR_FilterObject();

fieldset.AddField('string','Name','Name','True');
fieldset.AddField('Integer','Area Rank','Area_Rank__c','True');
fieldset.AddField('Id','Id','Id','True');
fieldset.AddField('Date','Created Date','CreatedDate','True');
fieldset.AddField('DateTime','Created Date','CreatedDate','True');
fieldset.AddField('string','Account Id','AKAM_Account_ID__c','True');
filter.fieldSet = fieldset;


filter.ClearFilter();
filter.inputQuery='select Name, Id, AKAM_Account_ID__c, OwnerId, CreatedDate, Area_Rank__c from Account' ;

filter.listOfFields[0].TextboxValue='abc or rat or *a or a* or *a* or <>cd';
filter.listOfFields[4].TextboxValue='<>abc and <>rat and *a and a* and *af*';
filter.listOfFields[1].TextboxValue='1';
filter.listOfFields[3].DateBoxa='9/12/2012';
filter.listOfFields[3].DateBoxb='10/12/2012';


filter.ApplyFilter();
OutputQuery = filter.OutputQuery;
System.debug(OutputQuery);

fieldset = new IR_FilterObject();
fieldset.AddField('Date','Created Date','CreatedDate','True');
fieldset.AddField('DateTime','Created Date','CreatedDate','True');
fieldset.AddField('string','Name','Name','True');
fieldset.AddField('Integer','Area Rank','Area_Rank__c','True');
fieldset.AddField('Id','Id','Id','True');
fieldset.AddField('string','Account Id','AKAM_Account_ID__c','True');
filter.fieldSet = fieldset;


filter.ClearFilter();
filter.inputQuery='select Name, Id, AKAM_Account_ID__c, OwnerId, CreatedDate, Area_Rank__c from Account' ;

filter.listOfFields[4].TextboxValue='abc or rat or *a or a* or *a* or <>cd';
filter.listOfFields[1].TextboxValue='<>abc and <>rat and *a and a* and *af*';
filter.listOfFields[2].TextboxValue='1';
filter.listOfFields[3].DateBoxa='9/12/2012';
filter.listOfFields[3].DateBoxb='10/12/2012';


filter.ApplyFilter();
OutputQuery = filter.OutputQuery;
System.debug(OutputQuery);

fieldset = new IR_FilterObject();
fieldset.AddField('Id','Id','Id','True');
fieldset.AddField('Date','Created Date','CreatedDate','True');
fieldset.AddField('DateTime','Created Date','CreatedDate','True');
fieldset.AddField('string','Name','Name','True');
fieldset.AddField('Integer','Area Rank','Area_Rank__c','True');

fieldset.AddField('string','Account Id','AKAM_Account_ID__c','True');
filter.fieldSet = fieldset;


filter.ClearFilter();
filter.inputQuery='select Name, Id, AKAM_Account_ID__c, OwnerId, CreatedDate, Area_Rank__c from Account' ;

filter.listOfFields[4].TextboxValue='abc or rat or *a or a* or *a* or <>cd';
filter.listOfFields[2].TextboxValue='<>abc and <>rat and *a and a* and *af*';
filter.listOfFields[3].TextboxValue='1';
filter.listOfFields[0].TextboxValue='asdas';
filter.listOfFields[1].DateBoxb='9/12/2012';
filter.listOfFields[1].DateBoxb='10/12/2012';


filter.ApplyFilter();
OutputQuery = filter.OutputQuery;
System.debug(OutputQuery);



fieldset = new IR_FilterObject();
fieldset.AddField('Id','Id','Id','True');
fieldset.AddField('Date','Created Date','CreatedDate','True');
fieldset.AddField('string','Name','Name','True');
fieldset.AddField('Integer','Area Rank','Area_Rank__c','True');

fieldset.AddField('string','Account Id','AKAM_Account_ID__c','True');
fieldset.AddField('string','Name','Name','True');
fieldset.AddField('string','Name','Name','True');
fieldset.AddField('string','Name','Name','True');
fieldset.AddField('string','Name','Name','True');
fieldset.AddField('string','Name','Name','True');
fieldset.AddField('DateTime','Created Date','CreatedDate','True');
filter.fieldSet = fieldset;

fieldset.AddField('string','Name','Name','True',new List<String>(),'value');
fieldset.AddField('Id','Id','Id','True',new List<String>(),'value');
fieldset.AddField('Date','Created Date','CreatedDate','True',new List<String>(),'value');
fieldset.AddField('DateTime','Created Date','CreatedDate','True',new List<String>(),'value');
fieldset.AddField('string','Name','Name','True',new List<String>(),'value');
fieldset.AddField('Integer','Area Rank','Area_Rank__c','True',new List<String>(),'value');




fieldset = new IR_FilterObject();

filter.fieldSet = fieldset;



fieldset = new IR_FilterObject();
fieldset.AddField('Date','Created','date','False');
fieldset.AddField('Date','Created','date','False');
fieldset.AddField('Date','Created','date','False');
fieldset.AddField('Date','Created','date','False');
fieldset.AddField('Date','Created','date','False');
fieldset.AddField('Date','Created','date','False');
fieldset.AddField('Date','Created','date','False');
fieldset.AddField('Date','Created','date','False');
fieldset.AddField('Date','Created','date','False');
fieldset.AddField('Date','Created','date','False');
fieldset.AddField('DateTime','Created','date','False');
fieldset.AddField('DateTime','Created','date','False');
fieldset.AddField('DateTime','Created','date');
filter.fieldSet = fieldset;
filter.setSortField('abcd');
filter.toggleSortOrder();
filter.InputQuery = 'limit';
string a= OutputQuery;
filter.Title = null;
a=filter.Title;

}

static testMethod void Filter_NegativeTest(){

IR_PageControllerBase pg = new IR_PageControllerBase();
IR_Filter filter = new IR_Filter();

filter.pageController=pg;
filter.inputQuery='select Name, Id, AKAM_Account_ID__c, OwnerId, CreatedDate, Area_Rank__c from Account' ;
filter.ReRenderIds='label';
filter.LimitSOQL=500;
filter.Status='status';
filter.DefaultOrderBy='Name';
filter.DefaultSortOrderDirection='Desc';
IR_FilterObject fieldset = new IR_FilterObject();
fieldset.AddField('string','Name','Name');
fieldset.AddField('Id','Id','Id');
fieldset.AddField('string','Account Id','AKAM_Account_ID__c','True');
fieldset.AddField('Date','Created Date','CreatedDate');
fieldset.AddField('DateTime','Created Date','CreatedDate');
fieldset.AddField('Integer','Area Rank','Area_Rank__c');

fieldset.AddField('string','Name','Name',new List<String>());
fieldset.AddField('Id','Id','Id',new List<String>());
fieldset.AddField('string','Account Id','AKAM_Account_ID__c','True',new List<String>());
fieldset.AddField('Date','Created Date','CreatedDate',new List<String>());
fieldset.AddField('DateTime','Created Date','CreatedDate',new List<String>());
fieldset.AddField('Integer','Area Rank','Area_Rank__c',new List<String>());
fieldset.AddField('Boolean','Gender','Gender',new List<String>());
fieldset.AddCustomBooleanField('Custom Field','true','false');
fieldset.AddField('other','Description','Description','false');
fieldset.AddField('Date','Created Date','CreatedDate','True');
fieldset.AddField('DateTime','Created Date','CreatedDate','True');

filter.fieldSet = fieldset;

filter.getInit();

filter.listOfFields[0].TextboxValue='* and *';
filter.listOfFields[2].TextboxValue='*AC*';
filter.listOfFields[5].TextboxValue='1';
filter.listOfFields[3].DateBoxa='9/12/2012';
filter.listOfFields[3].DateBoxb='';
filter.listOfFields[4].DateBoxa='9/12/2012';
filter.listOfFields[4].DateBoxb='';
filter.listOfFields[7].TextboxValue='wewr';
filter.listOfFields[6].TextboxValue='wewr';
filter.listOfFields[5].TextboxValue='wewr';
filter.listOfFields[4].TextboxValue='wewr';
filter.listOfFields[3].TextboxValue='wewr';
filter.listOfFields[2].TextboxValue='wewr';
filter.listOfFields[1].TextboxValue='wewr';


filter.ApplyFilter();
String OutputQuery = filter.OutputQuery;
filter.listOfFields[7].TextboxValue='';
filter.listOfFields[6].TextboxValue='';
filter.listOfFields[5].TextboxValue='';
filter.listOfFields[4].TextboxValue='';
filter.listOfFields[3].TextboxValue='';
filter.listOfFields[2].TextboxValue='';
filter.listOfFields[1].TextboxValue='';
filter.listOfFields[0].TextboxValue='';
filter.listOfFields[15].DateBoxa='9/12/2012';
filter.listOfFields[15].DateBoxb='9/12/2012';
filter.listOfFields[16].DateBoxa='9/12/2012';
filter.listOfFields[16].DateBoxb='9/12/2012';
filter.ApplyFilter();


}

}