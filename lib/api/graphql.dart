
final String portfolioQuery = """
query PortfolioOverview(\$id: Long!) {
  portfolio(id: \$id) {
    client: primaryContact {
      name
    }
    portfolioName: name
    shortName
    portfolioReport: portfolioReport(use15minDelayedPrice: true,
      calculateExpectedAmountBasedOpenTradeOrders: true) {
      marketValue: positionMarketValue
      cashBalance: accountBalance
      netAssetValue: marketValue
      investments: portfolioReportItems {
        security {
          name
          securityCode
        }
        amount
        positionValue: marketTradeAmount
        changePercent: valueChangeRelative
      }
    }
    graph:analytics(withoutPositionData:false,
      parameters: {
        paramsSet: {
          timePeriodCodes:"GIVEN"
          includeData:true
          drilldownEnabled:false
          limit: 0
        },
        includeDrilldownPositions:false
      }) {
      dailyValues:grouppedAnalytics(key:"1") {
        dailyValue:indexedReturnData {
          date
          portfolioMinus100:indexedValue
          benchmarkMinus100:benchmarkIndexedValue
        }
      }
    }
    tradeOrders(orderStatus:"4") {
      securityCode
      securityName
      amount
      typeName
      orderStatus
      transactionDate
    }
  }
}
""";
//note withoutPositionData false = slower query

final String securityQuery = """
query Security(\$securityCode: String) {
  securities( securityCode: \$securityCode ) {
    name
    securityCode
    marketData: latestMarketData {
      latestValue:close
    }
    url
    graph:marketDataHistory(timePeriodCode:"YEARS-1") {
      date:obsDate
      price:close
    }
    currency {
      currencyCode:securityCode
    }
  }
}
""";

final String transactionMutation = """
mutation addOrder(\$parentPortfolio: String, \$security: String, \$amount: String, \$price: String, \$currency: String, \$type: String, \$dateString: String) {
  importTradeOrders(tradeOrderList: [
    {
      parentPortfolio: \$parentPortfolio
      security: \$security
      amount: \$amount
      unitPrice: \$price
      currency: \$currency
      type: \$type
      transactionDate: \$dateString
      status: "4"
    }
  ])
}
""";