/**
 *  Description     :   This class is used to filter out the products.
 *
 *  Created Date    :   08/25/2015
 *
 *  Version         :   V_1.0 
 *   
 *  Revision Log    :   V_1.0 - Created
**/
global with sharing class RevRecProductListController { 
          
    //Variable to hold the page size
    Integer PAGE_SIZE;   
    
    //Integer defined for holding Page Number 
    public Integer pageNumber {get; set;} 
    public Integer totalPageNumber {get; set;}
    public string searchString {get;set;}
    public string errMsg {get;set;}
    public boolean showErr {get;set;}
    public String ruleId {get; set;}
    public String oppLineItemRow {get;set;}
    Public Boolean PBFlag{get;set;}
    
    //Initlize List
    public  List<List<productWrapper>> products {get;set;}
         
    //Constructer
    public RevRecProductListController() {
        
        //Setting default 
        pageNumber = 0;
        totalPageNumber = 1; 
        PAGE_SIZE = 20;
        errMsg = '';
        showErr = false;
        
        //Load defaults
        inIt();
    }
    
    public void inIt() {
        
        //Memory allocation
        products = new  List<List<productWrapper>>();
        
        //Populating list of list with value
        products.add(new List<productWrapper>());
        
        //Integer helpful for list of list population
        Integer i = 0;
        
        //String 
        string searchText = '';
        
        //Checking for fields
        if(string.isNotBlank(searchString)) 
            searchText = '%'+searchString+'%' ;
        
        //List of products
        List<Product2> filteredProducts  = new List<Product2>();
        
        //Checking if searchText is not blank
        if(string.isNotBlank(searchText))
            filteredProducts = [Select Id, Name, ProductCode, IsActive, Description, RevRecRule__r.Name, RevRecRule__c From Product2 Where Name Like : searchText AND IsActive = true Order By Name LIMIT 1000]; 
        else
            filteredProducts = [Select Id, Name, ProductCode, IsActive, Description, RevRecRule__r.Name, RevRecRule__c From Product2 WHERE IsActive = true ORDER BY Name LIMIT 1000];
            
        //Checking for the size
        if(filteredProducts.size() == 1000) {
            errMsg = Constants.MORE_THAN_1000_RECORDS;
            showErr = true;
        }
        else {
            errMsg = '';
            showErr = false;
        }
        
        //Loop over fileterd product
        for(Product2 Product : filteredProducts) {
        
            //Checking for integer value                
            if(i == PAGE_SIZE) {
                
                //adding new list to the list of list
                products.add(new List<productWrapper>());
                i=0;
            }
            
            products[products.size()-1].add(new productWrapper(product));
            i++;            
        }
        PBFlag= true;
    }
    
    //List of Price book entries
    public List<productWrapper> productsList {
        get{
            System.debug('product---'+products[pageNumber]);
            return products[pageNumber];
        } set; 
    }
    
     //Previous
    public void previous(){
      
        //Check list of list for size
        if(products.size() != 0) {
           
            //Decrease page number by 1
            pageNumber-=1;
            totalPageNumber = pageNumber + 1;
        }
    }
    
    //Next
    public void next(){
      
        //Checking for size of list of list
        if(products.size() >= 0) {
         
            //Increase page number by 1
            totalPageNumber= pageNumber + 1;
            pageNumber+=1;
            totalPageNumber +=1;
        } 
    }
    
    //First
    public void first() {
      
        //Checking for size of list of list
        if(products.size() >= 0) {
         
            //Increase page number by 1
            pageNumber = 0;
            totalPageNumber = 1;
        } 
    }
    
    //Last
    public void last(){
      
        //Checking for size of list of list
        if(products.size() >= 0) {
         
            //Increase page number by 1
            pageNumber = products.size() -1;
            totalPageNumber = products.size();
        } 
    }
    
    //Method to disable previous button 
    public Boolean getPreviousButtonDisabled() {
 
        //or when multiplication of currenjt page no. and page size is > then Paticipant list 
        return (pageNumber == products.size() || pageNumber == 0);
    }
    
    //Method to disable next button 
    public Boolean getNextButtonDisabled(){
 
        //disable when Index of the page is equal to total number of index OR WHEN THERE 
        return (pageNumber == products.size() || pageNumber == products.size()-1);
    }
    
    //Method is used to save the records
    public void saveResults() {
        
        //List of product to be updated
        List<Product2> productsToBeUpdated = new List<Product2>();
        
        for(productWrapper proWrap : productsList) { 
            System.debug('Product wrapper...@@@' + proWrap.product);
            productsToBeUpdated.add(proWrap.product);
        }
        
        //Debugs..
        System.debug('productsToBeUpdated...$$$'+productsToBeUpdated+'Size...$$$'+productsToBeUpdated.size());
        //Checking for size
        if(productsToBeUpdated.size() > 0)
            update productsToBeUpdated;
        PBFlag= false;
    }
    
    public void doSearch() {
        inIt();
    }
     
    //Wrapper class
    public class productWrapper {
        
        //Variables
        public Product2  product {get;set;}
        
        //Constructer
        public productWrapper(Product2 product) {
            this.product = product;
        }
    }
     //Used to fetch Contact for mobile user lookup using auto complete
    @RemoteAction
    global static List<RevRecRules__c> queryRules(String keyword) {
        List<RevRecRules__c> rules = new List<RevRecRules__c>();
        if (keyword != null && keyword.trim() != '') {
            keyword = '%' + keyword + '%';
            rules = [Select Id , Name , Recognition_Type__c from RevRecRules__c where Name like :keyword];
        } else
            rules = [Select Id , Name , Recognition_Type__c from RevRecRules__c where Active__c = true];
        
        return rules;
    }  
    
    public void blankMethodOnProductList() {
    	
        //Checking for the row count
        if(String.isNotBlank(oppLineItemRow)) {
            Id rId = null;
            if(String.isNotBlank(ruleId))
                rId = Id.valueOf(ruleId.trim());
            productsList[Integer.valueOf(oppLineItemRow)].product.RevRecRule__c = rId;
        }
    }
}