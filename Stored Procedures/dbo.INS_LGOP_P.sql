SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[INS_LGOP_P]
	@X XML
AS
BEGIN
	DECLARE @FileNo BIGINT,
	        @LogType VARCHAR(3),
	        @LogText NVARCHAR(4000);
	
	SELECT @FileNo  = @X.query('//Log').value('(Log/@fileno)[1]', 'BIGINT'),
	       @LogType = @X.query('//Log').value('(Log/@type)[1]', 'VARCHAR(3)'),
	       @LogText = @X.query('//Log').value('(Log/@text)[1]', 'NVARCHAR(4000)');
	
	IF ISNULL(@FileNo, 0) = 0 SET @FileNo = NULL;
	
	INSERT INTO dbo.Log_Operation
	         (
	           FIGH_FILE_NO ,
	           LOID ,
	           LOG_TYPE ,
	           LOG_TEXT 
	         )
	VALUES   (
	           @FileNo , -- FIGH_FILE_NO - bigint
	           0 , -- LOID - bigint
	           @LogType , -- LOG_TYPE - varchar(3)
	           @LogText 
	         );
END
GO
