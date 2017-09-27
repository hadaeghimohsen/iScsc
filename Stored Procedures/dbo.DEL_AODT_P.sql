SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[DEL_AODT_P]
	-- Add the parameters for the stored procedure here
	@Agop_Code BIGINT
  ,@Rwno INT
AS
BEGIN
	DELETE dbo.Aggregation_Operation_Detail
	WHERE AGOP_CODE = @Agop_Code
	  AND RWNO = @Rwno;
END
GO
