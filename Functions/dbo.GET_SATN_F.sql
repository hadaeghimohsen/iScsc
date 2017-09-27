SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date, ,>
-- Description:	<Description, ,>
-- =============================================
CREATE FUNCTION [dbo].[GET_SATN_F]
(
	@X XML
)
RETURNS XML
AS
BEGIN
	DECLARE @Rx XML
	       ,@FileNo BIGINT;
	
	SELECT @FileNo = @X.query('Fighter').value('(Fighter/@fileno)[1]', 'BIGINT');
	
	IF @FileNo = 0
	   RETURN '<Fighter><Attendance a="" b="" c="" d="" e="" f=""/></Fighter>';
	
	DECLARE @FirstWeekDay DATE
	       ,@LastWeekDay DATE;
	
	SET @FirstWeekDay = DATEADD(d, -1 * DATEPART(weekday, GETDATE()), GETDATE());
	SET @LastWeekDay = DATEADD(d, 7 - DATEPART(weekday, GETDATE()), GETDATE());
	DECLARE @A INT -- تعداد کل دفعات انگشت زده
	       ,@B INT -- تعداد روزهای حضور یافته
	       ,@C INT -- تعداد کل دفعات انگشت زده در هفته
	       ,@D INT -- تعداد حضور در روزهای هفته
	       ,@E INT -- کل دقایق حضور در باشگاه
	       ,@F INT -- میانگین دقایق حضور در باشگاه        
	
	SELECT @A = COUNT(*)
	      ,@B = COUNT(DISTINCT ATTN_DATE)
	      ,@E = SUM(ABS(DATEDIFF(mi, ENTR_TIME, ISNULL(EXIT_TIME, GETDATE()))))
	      ,@F = AVG(ABS(DATEDIFF(mi, ENTR_TIME, ISNULL(EXIT_TIME, GETDATE()))))
	  FROM dbo.Fighter f, dbo.Attendance A
	 WHERE f.FILE_NO = a.FIGH_FILE_NO
	   AND f.MBSP_RWNO_DNRM = a.MBSP_RWNO_DNRM
	   AND a.MBSP_RECT_CODE_DNRM = '004'
	   AND f.FILE_NO = @FileNo;
	
	SELECT @C = COUNT(*)
	      ,@D = COUNT(DISTINCT ATTN_DATE)
	  FROM dbo.Fighter f, dbo.Attendance A
	 WHERE f.FILE_NO = a.FIGH_FILE_NO
	   AND f.MBSP_RWNO_DNRM = a.MBSP_RWNO_DNRM
	   AND a.MBSP_RECT_CODE_DNRM = '004'
	   AND f.FILE_NO = @FileNo
	   AND a.ATTN_DATE BETWEEN @FirstWeekDay AND @LastWeekDay;
	
	SELECT @Rx = (
	   SELECT @A AS '@a'
	         ,@B AS '@b'
	         ,@C AS '@c'
	         ,@D AS '@d'
	         ,ISNULL(@E, 0) AS '@e'
	         ,ISNULL(@F, 0) AS '@f'
	      FOR XML PATH('Attendance'),ROOT('Fighter')
	);
	
	RETURN @Rx;
END
GO
