# GustiLogistics

Welcome to my *small business supply chain management web app*, which is currently hosted on [Heroku](https://www.heroku.com/). Although still in Beta, this application is already **in production**. It enables my former company, [Gustiamo](https://www.gustiamo.com/), to better manage their supply chain more efficiently and effectively via:
* Data Analytics and Visualization
* Forecasting of Inventory Reorder Dates and Quantities

### Tech Stack

* Ruby on [Rails](http://rubyonrails.org/) application, which makes particular use of the following [RubyGems](https://rubygems.org/):
  * [Bootstrap-Sass](https://github.com/twbs/bootstrap-sass/) for styling on the Front-End.
  * [jQuery](https://rubygems.org/gems/jquery-rails) for making [Ajax](https://en.wikipedia.org/wiki/Ajax_(programming)) requests.
  * [Chartkick](https://github.com/ankane/chartkick) for Data Visualizations.
  * [Roo](https://github.com/roo-rb/roo) for parsing Excel spreadsheets.

### Application Features

The app requires authentication to access, so below are sample images with notes pertaining to the most interesting and challenging parts. 

Upon **login** the app displays:
* An indexing of all products', along with their current quantities and reorder by dates. 

Note: Not all suppliers and products have been uploaded yet.

![alt text](/sample_images/ProductsIndexPage.png "Products List")

Links to two **spreadsheet uploaders** can be seen at the bottom-left of the above page which:
* Enable updates to the database on the client's end. 
* Are parsed as an argument in the [params hash](https://gorails.com/episodes/the-params-hash). 

![alt text](/sample_images/FileUploader.png "File Uploader")

A **calendar page**, which takes inspiration from this [RailsCast](http://railscasts.com/episodes/213-calendars) for design and implementation, and:
* Displays which products should be reordered based on calculated reorder dates. 
* Provides a context of time, which helps my former company envision the bigger picture of ordering, as they need to group orders from different vendors in one vessel from Italy. 

![alt text](/sample_images/CalendarPage.png "Calendar Prototype")

Clicking on a product link on the calendar pages takes you to a **product analysis page** which:
* Lists all vital stats like reorder dates, quantities and more
* Displays Top B2B customers and total B2C(retail) sales in a table and pie chart. 
* Ranks customers in the last 12 months into 6-month halves, as requested by the client. 

One of my goals in the next few weeks is to enable dynamic querying on the page for any given month range.  

![alt text](/sample_images/ProductAnalysisPage.png "Product Analysis")

My vision for this application is that it will:
* Handle all matters related to supply chain management, such as reorders calculations, and customer, product, and supplier analyses will take place within the app. 
* Generlizes to offering more servies, such as company communications and project management. 
* Becomes useful for other small "brick and mortar" businesses to use.
