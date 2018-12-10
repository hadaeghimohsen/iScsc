SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[CRET_INST_P]
	@X XML
AS
BEGIN
	BEGIN TRY
	   BEGIN TRAN T_CRET_INST_P
	   DECLARE @Rqid BIGINT
	          ,@DayInstallment INT
	          ,@CountInstallment INT;
	   
	   COMMIT TRAN T_CRET_INST_P;	   
	END TRY
	BEGIN CATCH 
	   ROLLBACK TRAN T_CRET_INST_P;
	END CATCH;
END
GO
