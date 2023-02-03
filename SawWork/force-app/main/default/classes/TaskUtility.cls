public with sharing class TaskUtility {
	
	private List<Task> taskList;
	
	public TaskUtility() {
		taskList = new List<Task>();
	}
	
	public List<Task> getTaskList() {
		return taskList;
	}
	
	public static Task createTask(Id whatId,String ownerId,String subject) { // To create a task
		
        Task ta = new Task();
        ta.WhatId = whatId;
        if(ownerId != null)
        	ta.OwnerId = ownerId;
        ta.Subject = subject;
        
        insert ta; 
        return ta;    
    }
    
    public void queue(Id whatId,String ownerId,String subject) { // Adding to list
        Task task = new Task();
        task.WhatId = whatId;
        if(ownerId != null)
        	task.OwnerId = ownerId;
        task.Subject = subject;
        
        taskList.add(task);
        
    }
    
    public List<Task> insertQueue() { // Insert all the queued up record
         insert taskList; // Null check ommitted to save LOC
         return taskList;  
    }
    
}