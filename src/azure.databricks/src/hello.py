{
 "cells": [
  {
   "cell_type": "markdown",
   "metadata": {
    "application/vnd.databricks.v1+cell": {
     "cellMetadata": {},
     "inputWidgets": {},
     "nuid": "ee353e42-ff58-4955-9608-12865bd0950e",
     "showTitle": false,
     "title": ""
    }
   },
   "source": [
    "# Default notebook\n",
    "\n",
    "This default notebook is executed using Databricks Workflows as defined in resources/dbx_dab.job.yml."
   ]
  },
  {
   "cell_type": "code",
   "execution_count": null,
   "metadata": {},
   "outputs": [],
   "source": []
  },
  {
   "cell_type": "code",
   "execution_count": null,
   "metadata": {},
   "outputs": [],
   "source": []
  },
  {
   "cell_type": "code",
   "execution_count": 2,
   "metadata": {},
   "outputs": [],
   "source": [
    "%load_ext autoreload\n",
    "%autoreload 2"
   ]
  },
  {
   "cell_type": "code",
   "execution_count": 0,
   "metadata": {
    "application/vnd.databricks.v1+cell": {
     "cellMetadata": {
      "byteLimit": 2048000,
      "rowLimit": 10000
     },
     "inputWidgets": {},
     "nuid": "6bca260b-13d1-448f-8082-30b60a85c9ae",
     "showTitle": false,
     "title": ""
    }
   },
   "outputs": [],
   "source": [
    "from dbx_dab import main\n",
    "\n",
    "main.get_taxis(spark).show(10)"
   ]
  }
 ],
 "metadata": {
  "application/vnd.databricks.v1+notebook": {
   "dashboards": [],
   "language": "python",
   "notebookMetadata": {
    "pythonIndentUnit": 2
   },
   "notebookName": "notebook",
   "widgets": {}
  },
  "kernelspec": {
   "display_name": "Python 3",
   "language": "python",
   "name": "python3"
  },
  "language_info": {
   "name": "python",
   "version": "3.11.4"
  }
 },
 "nbformat": 4,
 "nbformat_minor": 0
}
