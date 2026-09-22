import logging
from fastapi import APIRouter, Depends
from typing import List, Dict, Any

from app.services.mcp_service import MCPClientService
from app.auth import get_current_user
from app.models.user import User

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/api/companies", tags=["companies"])

@router.get("", response_model=List[Dict[str, Any]])
async def list_companies(current_user: User = Depends(get_current_user)):
    """List all companies from MCP."""
    if not MCPClientService.is_connected:
        await MCPClientService.connect()
    try:
        companies = await MCPClientService.list_companies(current_user.user_id)
        return companies or []
    except Exception as e:
        logger.warning("Error fetching companies from MCP: %s", e)
        return []

@router.get("/{company_name}/documents", response_model=List[Dict[str, Any]])
async def get_company_documents(company_name: str, current_user: User = Depends(get_current_user)):
    """Get all documents for a specific company from MCP."""
    if not MCPClientService.is_connected:
        await MCPClientService.connect()
    try:
        docs = await MCPClientService.get_documents(company_name, current_user.user_id)
        return docs or []
    except Exception as e:
        logger.warning("Error fetching documents for %s from MCP: %s", company_name, e)
        return []

@router.get("/{company_name}/details", response_model=Dict[str, Any])
async def get_company_details(company_name: str, current_user: User = Depends(get_current_user)):
    """Get details for a specific company from MCP."""
    if not MCPClientService.is_connected:
        await MCPClientService.connect()
    try:
        details = await MCPClientService.get_company_details(company_name, current_user.user_id)
        return details or {}
    except Exception as e:
        logger.warning("Error fetching details for %s from MCP: %s", company_name, e)
        return {}
