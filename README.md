# GustiLogistics

Welcome to my homemade *small business supply chain management web app*, which is currently hosted on [Heroku](https://www.heroku.com/). While working for a small food importer in New York City, I yearned to create a product like this. After become a software developer over the last year, I reached out to my former colleagues to finally make it happen. This [Rails](http://rubyonrails.org/) App now enables my former company [Gustiamo](https://www.gustiamo.com) to manage their supply chain more efficiently and effectively via custom Data Analytics and Visualization, and Forecasting. Now, my app creates visuals for each product's sales by top customers and uses this data to predict future reordering dates and quantities, both of which are rendered on a calendar. 

The app requires authentication to do any of the above, so I've included some sample images below pertaining to the most interesting and challenging parts. 

My client's users login to a listing of all products' current quantities and reorder by status. Styling throughout the application makes great use of the powerful [Bootstrap](https://github.com/twbs/bootstrap-sass/) gem.
![alt text](/sample_images/ProductsIndexPage.png "Products List")

The company's data all currently resides on local servers, which they interact with via a native accounting application. Because of none of their data currently resides in the cloud, I'm currently unable to access the relavant data via an API. I'm hoping this will change soon. Consequently, I built two file uploaders for them to update the logistics app's database on their end. Employees can update the B2B customer purchase sales and raw unit sales via an two Import models that parse excel spreadsheets. The uploaded sheet is available as an argument in ``params``, which I then parse with the [Roo](https://github.com/roo-rb/roo) gem's help. All valid data is writen to the database as necessary. The program rejects invalid files, redirects uses to the import page, and alerts the user of the error. 
![alt text](/sample_images/FileUploader.png "File Uploader")

The calculation of reorder dates are based on past sales, growth rates, and expected growth rates, as well as other parameters, such as lead time necessary for a supplier to prepare an order. This becomes more complicated with supplier "black holes" where they either can't produce and/or can't ship a product. If a calculated reorder date falls in this intervial, the next reorder date gets either bumped to the beginning of the "black hole" interval, or the end, depending on the current day of the year.

Below shows the calendar page, which displays which products should be reordered based on the calculated reorder dates. 
The calendar makes great use of a calendar helper module and HTML and CSS styling. Seeing order dates in the context of times helps my former company envision the bigger picture of ordering, as they need to group orders from different vendors in one vessel from Italy. 
![alt text](/sample_images/GustiLogisticsCalendar.png "Calendar Prototype")

Reorder quantities are also based on past sales, growth rates, and expected growth rates, as well as "cover time", or the amount of time the next reorder will be expected to last to last. The cover time varies when reorder dates land in the aforementioned "black hole" ordering periods. For instance, if a product can't be ordered for the next 6-7 months, the quantity will be increased if normal cover time is 4 months. A product's current inventory is also taken into consideration in cases where a product needs to be reorderd sooner than needed. 

And here's an example of an individual Product analysis page. It lists and displays top B2B customers and total B2C(retail) sales for a given product. Currently, sales are broken into the last 6 full months, and the previous 6 full months before that, as requested by the client. One of my goals in the next few weeks is to enable dynamic querying for any given month range as well. The pie charts are thanks to [Chartkick](https://github.com/ankane/chartkick) gem. 
![alt text](/sample_images/ProductShowPage.png "Product Analysis")

Although still in Beta, this app is already a "value-add" to the company. My near-future vision for the application is that all matters related to supply chain management, such as reorders calculations, customer, product, and supplier analyses, will take place in the app. I hope it could generalize even more, allowing tasks like company communications and project management to be done within the app. In addition, it could be useful for other small "brick and mortar" businesses to use. 
