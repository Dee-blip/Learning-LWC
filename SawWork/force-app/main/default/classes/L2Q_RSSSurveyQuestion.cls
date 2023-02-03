Public class L2Q_RSSSurveyQuestion {
	public Survey_Question__c question {
		get;
		set;
	}
	public List<String> choices {get;set;} 
	Public static Integer AutoNumber = 0;
	public Integer UniqueNumber {
		get;
		set;
	}
	public String UniqueName {
		get;
		set;
	}
	public List<L2Q_SelectOptions > choicesObj {
		get;
		set;
	} 
	public L2Q_RSSSurveyQuestion()

	{
		question = new Survey_Question__c();
		UniqueNumber = null;
		UniqueName = null;

	}
	public L2Q_RSSSurveyQuestion(Survey_Question__c q) {
		question = q;
		if (q.Type__c != 'Free Text')
			choicesObj = stringToSelectOptions1(q.Choices__c);
		AutoNumber++;
		UniqueNumber = null;
		UniqueName = null;
	}

	private List<L2Q_SelectOptions > stringToSelectOptions1(String str) {
		List<String> strList;
		List<L2Q_SelectOptions > returnVal = new List<L2Q_SelectOptions > (); // // to change to select options rajesh
		if (!String.isBlank(str)) {
			strList = str.split('\n');

			for (String s: strList) {
				if (s != '') {
					returnVal.add(new L2Q_SelectOptions(s.trim(), s.trim()));
				}
			}
		}

		return returnVal;
	}

	public class L2Q_SelectOptions {
		public string label;
		public string value;
		public L2Q_SelectOptions(String label, String value) {
			this.label = label;
			this.value = value;

		}
	}
}