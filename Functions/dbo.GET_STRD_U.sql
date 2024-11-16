SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date, ,>
-- Description:	<Description, ,>
-- =============================================
CREATE FUNCTION [dbo].[GET_STRD_U]
(
	@X XML
)
RETURNS NVARCHAR(MAX)
AS
BEGIN
	DECLARE @Type VARCHAR(3),
	        @Rqid BIGINT,
	        @Code BIGINT,
	        @RsltDesc NVARCHAR(MAX);
	
	SELECT @Type = @x.query('//Request').value('(Request/@type)[1]', 'VARCHAR(3)');
	
	IF @Type = '001' -- برای نمایش اطلاعات و مشخصات خریدار در درآمد متفرقه
	BEGIN
	   SELECT @Rqid = @x.query('//Request').value('(Request/@rqid)[1]', 'BIGINT');
	   SELECT 
	      @RsltDesc = 
         (
            SELECT TOP 1 CASE f.FGPB_TYPE_DNRM
                        WHEN '005' THEN 
                           N'فاکتور : '  + CAST(r.INVC_NUMB AS NVARCHAR(10)) + N' -> ' + CHAR(10) +
                           N'نام مشتری : ' + ISNULL(fp.FRST_NAME, N'مهمان') + N' ' + ISNULL(fp.LAST_NAME, N'آزاد') + N' - ' + CHAR(10) +
                           N'تلفن همراه : ' + CASE WHEN fp.CELL_PHON IS NULL THEN N'* بدون شماره موبایل' ELSE fp.CELL_PHON END + CHAR(10) + 
                           N'کد ملی : ' + CASE WHEN fp.NATL_CODE IS NULL THEN N'* بدون کد ملی' ELSE fp.NATL_CODE END 
                        ELSE 
                           N'شماره فاکتور : '  + CAST(r.INVC_NUMB AS NVARCHAR(10)) + CHAR(10) +
                           N'نام مشتری : ' + F.NAME_DNRM + CHAR(10) +
                           N'تلفن همراه : ' + CASE WHEN f.CELL_PHON_DNRM IS NULL THEN N'* بدون شماره موبایل' ELSE f.CELL_PHON_DNRM END + CHAR(10) + 
                           N'کد ملی : ' + CASE WHEN f.NATL_CODE_DNRM IS NULL THEN N'* بدون کد ملی' ELSE f.NATL_CODE_DNRM END + CHAR(10)
                   END 
              FROM dbo.Request_Row rr, dbo.Fighter f LEFT OUTER JOIN dbo.Fighter_Public fp ON f.FILE_NO = fp.FIGH_FILE_NO AND fp.RQRO_RQST_RQID = @Rqid AND fp.RECT_CODE = '001'
             WHERE rr.RQST_RQID = @Rqid
               AND rr.FIGH_FILE_NO = f.FILE_NO
         )
       FROM dbo.Request r
      WHERE r.RQID = @Rqid;
	END
	ELSE IF @Type = '002' -- نمایش توضیحات برای ردیف هزینه های فاکتور ها
	BEGIN
	   SELECT @Rqid = @x.query('//Request').value('(Request/@rqid)[1]', 'BIGINT'),
	          @Code = @x.query('//Request').value('(Request/@code)[1]', 'BIGINT');
	   
	   SELECT
	      @RsltDesc = (
	         CASE r.RQTP_CODE
	              WHEN '016' THEN 
	                   (SELECT CASE 
	                                WHEN ISNULL(e.NUMB_CYCL_DAY, 0) > 0 OR ISNULL(e.MIN_TIME, '00:01:00') > '00:01:00' THEN 
	                                     N'ساعت ورود : ' + CONVERT(VARCHAR(5), pd.MDFY_DATE, 8) + N' - ' + 
	                                     N'ساعت خروج : ' + CONVERT(VARCHAR(5), pd.EXPR_DATE, 8)
	                                ELSE N''
	                           END	                           
	                     FROM dbo.Payment_Detail pd, dbo.Expense e
	                    WHERE pd.PYMT_RQST_RQID = @Rqid
	                      AND pd.CODE = @Code
	                      AND pd.EXPN_CODE = e.CODE) + 
	                   ISNULL((SELECT f.NAME_DNRM
	                      FROM dbo.Payment_Detail pd, dbo.Fighter f
	                     WHERE pd.PYMT_RQST_RQID = @Rqid
	                       AND pd.code = @code
	                       AND pd.FIGH_FILE_NO = f.FILE_NO), N'')
	         END 
	      ) 
	    FROM dbo.Request r
	   WHERE r.RQID = @Rqid;
	END 
	ELSE IF @Type = '003'
	BEGIN
	   SELECT @Code = @x.query('//Request').value('(Request/@code)[1]', 'BIGINT');
	   
	   SELECT
	      @RsltDesc = (
	         CASE 
	              WHEN a.EXIT_TIME IS NULL THEN 
	                  (SELECT N'مشتری گرامی مدت زمان حضور شما ' + CAST(cm.CLAS_TIME AS NVARCHAR(3)) + N' دقیقه میباشد. زمان خروج شما در ساعت' + CONVERT(VARCHAR(5), DATEADD(MINUTE, cm.CLAS_TIME, a.ENTR_TIME)) + N' تنظیم شده است. دقت فرمایید که درصورت تایم اضافه با کسر جلسه یا هزینه جداگانه گرفته میشود. از توجه شما متشکریم'
	                    FROM dbo.Club_Method cm
	                   WHERE cm.CODE = a.cbmt_code_dnrm)
	              ELSE ''
	         END 
	      ) 
	    FROM dbo.Attendance a
	   WHERE a.CODE = @Code;
	END 
	RETURN @RsltDesc; 
END
GO
