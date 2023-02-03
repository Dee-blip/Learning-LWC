public class L2Q_MdtWrapper {
  public class FieldSet {
    public String fieldApiname;
    public Boolean required;
    public string fieldWidth;
  }
  public String objectName;
  public Integer recordLimit;
  public Integer maxrecordCreation;
  public String orderby;
  public string uomfd;
  public string filter;
  public string readonlyStatuscondition;
  public string cpheader;
  public List<FieldSet> fieldSet;
  public string nullclonefield; // Rajesh SFDC-7368
  public String countrysplitreadStatus;  // Rajesh SFDC-7368
  public L2Q_MdtWrapper() {
  }
}