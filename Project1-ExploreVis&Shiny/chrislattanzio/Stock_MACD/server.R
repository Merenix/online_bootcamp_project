# server.R

library(quantmod)
library(ggplot2) 
server = shinyServer(function(input, output) {

  dataInput = reactive({

    sym = input$symb
    from = input$dates[1]
    to = input$dates[2]
    
    fd = format(from, "%d")
    fy = format(from, "%Y") 
    fm = format(from, "%m")
    
    td = format(to, "%d")
    ty = format(to, "%Y") 
    tm = format(to, "%m")
    
    # Get stock data from Yahoo Finance
    sym_url = paste("http://real-chart.finance.yahoo.com/table.csv?s=",sym,"&a=",fm,"&b=",fd,"&c=",fy,"&d=",tm,"&e=",td,"&f=",ty,"&g=d&ignore=.csv",sep = "")
    
    yahoo.read = function(sym_url){
      dat = read.table(sym_url,header=TRUE,sep=",")
      df = dat[,c(1,7)]
      df$Date <- as.Date(as.character(df$Date))
      return(df)}
    
    mydata  = yahoo.read(sym_url)
    mydata = mydata[order(mydata$Date,decreasing = FALSE ),]
    rownames(mydata) = NULL
    
    macd.maType='EMA'
    fast=input$fast
    slow=input$slow
    sig=input$sig
    
    # 1. Call TTR MACD function and test last() values against expected values 
    v = MACD(x=as.vector(mydata['Adj.Close']), nFast=fast, nSlow=slow, nSig=sig, maType = macd.maType )
    
    mydata = merge(mydata,v, by.x = 0, by.y =0)
    mydata = mydata[order(mydata$Date),]
    mydata$direction = (mydata$macd-mydata$signal)
    mydata$Trader_Action <- ifelse((mydata$macd-mydata$signal) >0, "Buy", "Sell")
    mydata = na.omit(mydata)
    
  })

  
  output$plot1 <- renderPlot({
    

    p1 = ggplot(data = dataInput(), aes(x=Date,y=direction)) + geom_bar(aes(fill = Trader_Action ), stat = "identity")
    p2 = p1 + geom_line(aes(y=dataInput()$macd,colour="MACD")) 
    p3 = p2 + geom_line(aes(y=dataInput()$signal,colour="Signal"))
    p4 = p3 + xlab(" ") + ylab(" ") + labs(title=paste("MACD and Signal Indicators",input$symb) )
    p4 + theme(plot.title = element_text(hjust = 0.5),legend.title=element_blank())
    
  })
  
  output$plot2 <- renderPlot({
    

    pp1 = ggplot(data = dataInput(), aes(x=Date,y=Adj.Close))
    pp2 = pp1 + geom_line(aes(y=dataInput()$Adj.Close,colour="Adj.Close")) 
    pp3 = pp2 + xlab(" ") + ylab(" ") + labs(title=paste("Adjusted Closing Price for",input$symb) )
    pp3 + theme(plot.title = element_text(hjust = 0.5),legend.title=element_blank())
    
  
  })
  
  
})