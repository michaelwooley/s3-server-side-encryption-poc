# POC: AWS S3 sse 

## Notes

- _Should still verify that this all works when we use a custom origin._
- Reference modules:
  - [Using AES256](https://registry.terraform.io/modules/cloudposse/cloudfront-s3-cdn/aws/latest)
  - [Also using AES256](https://registry.terraform.io/modules/QuiNovas/cloudfront/aws/latest)
- Attempting to use a bucket-wide master key (i.e. do not create KMS key yourself) does not work.
- [According to this doc](https://docs.aws.amazon.com/AmazonS3/latest/userguide/UsingServerSideEncryption.html), no additional cost incurred to do this.  

## AWS Credentials

I am using the test account associated with `whoisnamecombo@gmail.com`.
