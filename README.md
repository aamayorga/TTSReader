# TTSReader

<img src="https://img.shields.io/badge/platform-iOS-blue.svg?style=flat" alt="Platform iOS" />

## Introduction
**TTSReader** is an app that downloads articles from the web and reads them back to you using the built-in iOS Text-to-Speech reader.

## Usage
* Download and save articles from your favorite news websites.
* Have your saved articles be read back, so all you need to do is listen!

## Screenshots
![TTSReaderShareSheet](Screenshots/ShareSheet.png)
![TTSReaderSaved](Screenshots/Saved.png)
![TTSReaderArticleList](Screenshots/ArticleList.png)
![TTSReaderArticleReader](Screenshots/ArticleReader.png)

## Setup

Delete this file:

```MercuryAPI.swift
```

Go to https://mercury.postlight.com/web-parser/ to get your own API key

Replace line in MercuryConstants.swift with your API Key:

```static let ApiKey = MercuryClient.ApiKey // REPLACE THIS LINE
```
