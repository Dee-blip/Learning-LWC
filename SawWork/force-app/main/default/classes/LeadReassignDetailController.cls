/* Author: Ruchika Sharma
    Version: 1.0
    Created date: 01/03/2018
    SFDC-2331: Project Agility- modify lead reassign to support lightening and list view.
*/
public class LeadReassignDetailController {
 
  private Id id;
 
  public LeadReassignDetailController(ApexPages.StandardController controller) {
    id = controller.getRecord().Id;
  }
   
  public PageReference forwardToListController() {
    PageReference pr = Page.LeadReassign;
    pr.getParameters().put('id', id);
    return pr;
  }
}