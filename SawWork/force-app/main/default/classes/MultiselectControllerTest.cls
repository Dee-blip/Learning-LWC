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
private class MultiselectControllerTest {
    static testMethod void testMultiselectController() {
        System.runAs(utilTestClass.getTestRunUser())
        {
        MultiselectController c = new MultiselectController();
        
        c.leftOptions = new List<SelectOption>();
        c.rightOptions = new List<SelectOption>();

        c.leftOptionsHidden = 'A&a&b&b&C&c';
        c.rightOptionsHidden = '';
        
        System.assertEquals(c.leftOptions.size(), 3);
        System.assertEquals(c.rightOptions.size(), 0);
        }
    }
    static testMethod void testMultiselectComponentController(){
      System.runAs(utilTestClass.getTestRunUser())
        {
            MultiSelectComponentController cc = new MultiSelectComponentController();
            cc.options = new List<SelectOption>();
            
            //private void setOptions(SelectOption[] options, String value) {
                String value = 'A&b&c';
                cc.options.clear();
                String[] part = value.split('&');
                for (Integer i=0; i<part.size()/2; i++) {
                    cc.options.add(new SelectOption(EncodingUtil.urlDecode(part[i*2], 'UTF-8'), 
                      EncodingUtil.urlDecode(part[(i*2)+1], 'UTF-8')));
                }
            
             cc.selectedOptions = new List<SelectOption>();

                String values = 'A&b&c';
                cc.selectedOptions.clear();
                String[] parts = values.split('&');
                for (Integer i=0; i<parts.size()/2; i++) {
                    cc.selectedOptions.add(new SelectOption(EncodingUtil.urlDecode(parts[i*2], 'UTF-8'), 
                      EncodingUtil.urlDecode(parts[(i*2)+1], 'UTF-8')));
                }
            
            
            
            
            /*MultiselectController cs = new MultiselectController();
                
            cs.setOptions(cc.options, 'A&a&B&b&C');
            cs.setOptions(cc.selectedOptions, 'A&a&B');*/
            cc.selected = new List<String>();
            cc.deselected = new List<String>();
            
             //String[] selectedString = new String[]{'A','a','B'};
            //String[] deselectedString = ['A','a','B'];

            cc.selected.add('A');
            cc.selected.add('a');
            cc.deselected.add('A');
            cc.deselected.add('a');
            
            
            
            cc.selecting();
            cc.deselecting();
        }
    } 
}