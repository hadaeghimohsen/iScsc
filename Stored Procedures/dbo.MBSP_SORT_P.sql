SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[MBSP_SORT_P]
	-- Add the parameters for the stored procedure here
	@X XML 
AS
BEGIN
	BEGIN TRY
	BEGIN TRAN [T$CYCL_SORT_P]
	
	-- Local Params
	DECLARE @FileNo BIGINT, 
	        @MbspRwno SMALLINT,
	        @MbspEndDate DATE;
	        
	SELECT @FileNo      = @X.query('//Member_Ship').value('(Member_Ship/@fileno)[1]', 'BIGINT'),
	       @MbspRwno    = @X.query('//Member_Ship').value('(Member_Ship/@rwno)[1]', 'SMALLINT'),
	       @MbspEndDate = @X.query('//Member_Ship').value('(Member_Ship/@enddate)[1]', 'DATE');
	
	-- Local Vars 
	DECLARE @XTmp XML,
	        @Rqid BIGINT, 
	        @RqroRwno SMALLINT,
	        @StrtDate DATE,
	        @EndDate DATE,
	        @NumbOfDayDnrm INT,
	        @NumbOfAttnMont INT,
	        @SumNumbAttnMontDnrm INT,
	        @StrtTime TIME(0),
	        @EndTime TIME(0),
	        @ctgycode BIGINT,
	        @cbmtcode BIGINT;
	
	DECLARE C$Mbsp CURSOR FOR
	   SELECT ms.RQRO_RQST_RQID, ms.RQRO_RWNO, ms.STRT_DATE, ms.END_DATE, ms.NUMB_OF_DAYS_DNRM,
	          ms.NUMB_OF_ATTN_MONT, ms.SUM_ATTN_MONT_DNRM, CAST(ms.STRT_DATE AS TIME(0)), CAST(ms.END_DATE AS TIME(0)),
	          ms.FGPB_CTGY_CODE_DNRM, ms.FGPB_CBMT_CODE_DNRM
	     FROM dbo.Member_Ship ms
	    WHERE ms.FIGH_FILE_NO = @FileNo
	      AND ms.RWNO > @MbspRwno
	      AND ms.RECT_CODE = '004'
	      AND ms.VALD_TYPE = '002'
	      AND CAST(ms.STRT_DATE AS DATE) >= CAST(GETDATE() AS DATE)
	      AND (ms.NUMB_OF_ATTN_MONT = 0 OR ms.NUMB_OF_ATTN_MONT > ms.SUM_ATTN_MONT_DNRM)
	    ORDER BY ms.RWNO;
   
   OPEN [C$Mbsp];
   L$Loop:
   FETCH [C$Mbsp] INTO @Rqid, @RqroRwno, @StrtDate, @EndDate, @NumbOfDayDnrm, @NumbOfAttnMont, @SumNumbAttnMontDnrm, @StrtTime, @EndTime, @ctgycode, @cbmtcode;
   
   IF @@FETCH_STATUS <> 0
      GOTO L$EndLoop;
   
   -- ابتدا باید تاریخ دوره جدید که میخواهیم ویرایش کنیم را درست کنیم
   SET @StrtDate = DATEADD(DAY, 1, @MbspEndDate);
   SET @EndDate = DATEADD(DAY, @NumbOfDayDnrm - 1, @StrtDate);
      
   SET @XTmp = (
       SELECT @Rqid AS '@rqid',
              (
                 SELECT @FileNo AS '@fileno',
                        @RqroRwno AS '@rwno',
                        (
                           SELECT @StrtDate AS '@strtdate',
                                  @EndDate AS '@enddate',
                                  1 AS '@prntcont',
                                  0 AS '@numbmontofer',
                                  @NumbOfAttnMont AS '@numbofattnmont',
                                  @SumNumbAttnMontDnrm AS '@sumnumbattnmont',
                                  @StrtTime AS '@strttime',
                                  @EndTime AS '@endtime',
                                  '' AS '@resnapbscode',
                                  N'مرتب کردن اطلاعات دوره های پشت سر هم' AS '@resndesc'
                              FOR XML PATH('Member_Ship'), TYPE                               
                        )
                    FOR XML PATH('Request_Row'), TYPE               
              )
          FOR XML PATH('Request'), ROOT('Process'), TYPE
   );
   -- گام اول برای ذخیره کردن ثبت موقت اطلاعات
   EXEC dbo.MBSP_TCHG_P @X = @XTmp; -- xml
   
   SET @XTmp = (
       SELECT @Rqid AS '@rqid',
              (
                 SELECT @FileNo AS '@fileno',
                        @RqroRwno AS '@rwno',
                        (
                           SELECT @cbmtcode AS '@cbmtcode',
                                  @ctgycode AS '@ctgycode',
                                  '001' AS '@editpymt'
                              FOR XML PATH('Member_Ship'), TYPE
                        )
                    FOR XML PATH('Request_Row'), TYPE
                    
              )
          FOR XML PATH('Request'), ROOT('Process'), TYPE
   );   
   -- گام دوم ذخیره کردن نهایی اطلاعات   
   EXEC dbo.MBSP_SCHG_P @X = @XTmp; -- xml
   
   -- گام اخر تغییر تاریخ برای دوره بعدی
   SET @MbspEndDate = @EndDate;
   
   GOTO L$Loop;
   L$EndLoop:
   CLOSE [C$Mbsp];
   DEALLOCATE [C$Mbsp];
	
	COMMIT TRAN [T$CYCL_SORT_P]
	END TRY
	BEGIN CATCH
	
	DECLARE @ErorMesg NVARCHAR(MAX) = ERROR_MESSAGE();
	RAISERROR(@ErorMesg , 16, 1);
	ROLLBACK TRAN [T$CYCL_SORT_P]
	
	END CATCH
END
GO
