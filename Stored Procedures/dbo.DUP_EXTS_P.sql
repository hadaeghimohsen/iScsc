SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[DUP_EXTS_P]
	-- Add the parameters for the stored procedure here
	@X XML
AS
BEGIN
	BEGIN TRY
	   BEGIN TRANSACTION T$DUP_EXTS_P
	   
	   -- Local Parameters
	   DECLARE @Extpcode BIGINT,
	           @FromHour DATETIME,
	           @ToHour DATETIME,
	           @GapHour INT,
	           @Qnty INT;
	           
      SELECT @ExtpCode = @X.query('//OpIran').value('(OpIran/@extpcode)[1]', 'BIGINT'),
             @FromHour = @X.query('//OpIran').value('(OpIran/@fromhour)[1]', 'DATETIME'),
             @ToHour = @X.query('//OpIran').value('(OpIran/@tohour)[1]', 'DATETIME'),
             @GapHour = @X.query('//OpIran').value('(OpIran/@gaphour)[1]', 'INT'),
             @Qnty = @X.query('//OpIran').value('(OpIran/@qnty)[1]', 'INT');
      
      -- Local Variables
      DECLARE @fromh INT = DATEPART(HOUR, @FromHour),
              @toh INT = DATEPART(HOUR, @ToHour),
              @i INT,
              @j DATETIME;
              
      SELECT @i = @fromh,
             @j = @FromHour;
      WHILE(@i <= @toh)
      BEGIN
         IF NOT EXISTS(SELECT * FROM dbo.Expense_Type_Step a WHERE a.EXTP_CODE = @Extpcode AND a.FROM_TIME = @j AND a.TO_TIME = DATEADD(HOUR, @GapHour, @j))
         BEGIN
            INSERT INTO dbo.Expense_Type_Step ( EXTP_CODE ,CODE ,NAME ,QNTY ,FROM_TIME ,TO_TIME ,STAT )
            VALUES (@Extpcode, dbo.GNRT_NVID_U(), @i, @Qnty, @j, DATEADD(HOUR, @GapHour, @j), '002');
         END           
         
         SELECT @i += @GapHour,
                @j = DATEADD(HOUR, @GapHour, @j);
      END 

	   COMMIT TRANSACTION [T$DUP_EXTS_P]	
	END TRY
	BEGIN CATCH
	   DECLARE @ErorMesg NVARCHAR(MAX) = ERROR_MESSAGE();
	   RAISERROR(@ErorMesg, 16, 1);
	   ROLLBACK TRANSACTION [T$DUP_EXTS_P]
	END CATCH
END
GO
