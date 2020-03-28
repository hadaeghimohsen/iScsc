SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[SET_IMAG_P]
   @X XML
AS 
BEGIN
   BEGIN TRY
--      EXEC master..sp_configure 'show advanced options', 1; 
--      RECONFIGURE; 
--      EXEC master..sp_configure 'Ole Automation Procedures', 1; 
--      RECONFIGURE; 
--      EXEC master..sp_addsrvrolemember @loginame = N'ARTAUSER', @rolename = N'bulkadmin'

      BEGIN TRAN [T$SET_IMAG_P];
      
      Declare @FileName nvarchar(MAX) ,
              @FileId varchar(MAX),
              @DestType varchar(3),
              @FileNo bigint,
              @DcmtCode varchar(2),
              @ActnType varchar(3),
              @Img VARBINARY(MAX),
              @SqlStmt nvarchar(MAX);      
      
      select @FileName = @X.query('//Image').value('(Image/@filename)[1]', 'NVARCHAR(MAX)')
            ,@DestType = @X.query('//Image').value('(Image/@desttype)[1]', 'VARCHAR(3)')
            ,@FileId = @X.query('//Image').value('(Image/@fileid)[1]', 'VARCHAR(MAX)')
            ,@FileNo = @X.query('//Image').value('(Image/@fileno)[1]', 'BIGINT')
            ,@DcmtCode = @X.query('//Image').value('(Image/@dcmtcode)[1]', 'VARCHAR(2)')
            ,@ActnType = @X.query('//Image').value('(Image/@actntype)[1]', 'VARCHAR(3)');
      
      -- Save Image_Document
      IF @DestType = 'p'
      BEGIN
         IF @ActnType = '001' -- Update image from filepath in hard disk
         BEGIN
            SET @SqlStmt = 
               N'SELECT @Img=CONVERT(VARBINARY(MAX), BulkColumn) 
                  FROM OPENROWSET(BULK ''' + @FileName + ''', SINGLE_BLOB) AS X;';
            
            exec sp_executesql @sqlstmt, N'@Img VARBINARY(MAX) output', @Img OUTPUT;
            
            -- Update Image in database
            UPDATE img
               set img.IMAG = (cast('' as XML).value('xs:base64Binary(sql:variable("@Img"))', 'VARCHAR(MAX)'))
              FROM Image_Document img, Receive_Document rd, Request_Row rr , Request r, Request_Regulation_History rrh
                  ,Request_Requester rqrq ,Request_Document rqd, Document_Spec ds
             where img.RCDC_RCID = rd.RCID
               
               and rd.RQRO_RQST_RQID = rr.RQST_RQID 
               AND rd.RQRO_RWNO = rr.RWNO
               
               and rr.RQST_RQID = r.RQID
               and rr.FIGH_FILE_NO = @FileNo
               
               and r.RQTP_CODE IN ('001', '025') -- First Admission
               
               and r.rqid = rrh.RQST_RQID
               and r.rqtp_code = rqrq.RQTP_CODE
               and r.RQTT_CODE = rqrq.RQTT_CODE
               
               and rqrq.REGL_YEAR = rrh.REGL_YEAR
               and rqrq.REGL_CODE = rrh.REGL_CODE
               
               and rqrq.code = rqd.RQRQ_CODE
               
               and rd.RQDC_RDID = rqd.RDID
               
               and rqd.DCMT_DSID = ds.DSID
               and ds.DCMT_CODE = @DcmtCode;
         END
         ELSE IF @ActnType = '002' -- Update fileid 
         BEGIN
            -- Update fileid in database
            UPDATE img
               set img.[FILE_ID] = @FileId
              FROM Image_Document img, Receive_Document rd, Request_Row rr , Request r, Request_Regulation_History rrh
                  ,Request_Requester rqrq ,Request_Document rqd, Document_Spec ds
             where img.RCDC_RCID = rd.RCID
               
               and rd.RQRO_RQST_RQID = rr.RQST_RQID 
               AND rd.RQRO_RWNO = rr.RWNO
               
               and rr.RQST_RQID = r.RQID
               and rr.FIGH_FILE_NO = @FileNo
               
               and r.RQTP_CODE IN ('001', '025') -- First Admission
               
               and r.rqid = rrh.RQST_RQID
               and r.rqtp_code = rqrq.RQTP_CODE
               and r.RQTT_CODE = rqrq.RQTT_CODE
               
               and rqrq.REGL_YEAR = rrh.REGL_YEAR
               and rqrq.REGL_CODE = rrh.REGL_CODE
               
               and rqrq.code = rqd.RQRQ_CODE
               
               and rd.RQDC_RDID = rqd.RDID
               
               and rqd.DCMT_DSID = ds.DSID
               and ds.DCMT_CODE = @DcmtCode;
         END
      END
      -- Save Expense
      ELSE IF @DestType = 'e'
      BEGIN
         Print 'Save Fileid in expense';
      END
      
      COMMIT TRAN [T$SET_IMAG_P];
   END TRY
   BEGIN CATCH
      DECLARE @EROR nvarchar(MAX);
      SET @EROR = Error_Message();
      RAISERROR(@EROR, 16, 1);
      ROLLBACK TRAN [T$SET_IMAG_P];
   END CATCH;
END;
GO
