SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE VIEW [dbo].[D$AEAT] AS SELECT VALU, DOMN_DESC FROM APP_DOMAIN WHERE CODE = 'D AEAT'
GO
