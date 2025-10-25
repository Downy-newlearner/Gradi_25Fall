# Cursor AI 설정 가이드

## Figma MCP 서버 설정

Cursor AI에서 Figma 디자인을 읽고 코드로 변환할 수 있도록 MCP(Model Context Protocol) 서버를 설정하는 방법입니다.

### 1. Figma API 키 발급

1. [Figma 계정 설정](https://www.figma.com/settings)으로 이동
2. **Personal Access Tokens** 섹션 찾기
3. **Generate new token** 클릭
4. 토큰 이름 입력 (예: "Gradi Development")
5. 생성된 토큰 복사 (⚠️ 한 번만 표시되므로 안전하게 보관!)

### 2. MCP 설정 파일 생성

프로젝트 루트에서 다음 명령 실행:

```bash
# .cursor 디렉토리 생성 (이미 있으면 생략)
mkdir -p .cursor

# 템플릿 파일 복사
cp .cursor/mcp.json.example .cursor/mcp.json
```

### 3. API 키 설정

`.cursor/mcp.json` 파일을 열고 `YOUR_FIGMA_API_KEY_HERE`를 발급받은 API 키로 교체:

```json
{
  "mcpServers": {
    "Figma": {
      "command": "npx",
      "args": ["-y", "figma-developer-mcp", "--stdio"],
      "env": {
        "FIGMA_API_KEY": "figd_YOUR_ACTUAL_API_KEY_HERE",
        "FIGMA_FILE_KEY": "lzHEWBZmLDENjELGjlRkyB",
        "FIGMA_NODE_ID": "2001:405"
      }
    }
  }
}
```

### 4. Cursor 재시작

- Cursor를 완전히 종료하고 다시 시작
- 또는 Cursor 명령 팔레트(`Cmd+Shift+P` / `Ctrl+Shift+P`)에서 "Reload Window" 실행

### 5. 설정 확인

Cursor AI 채팅에서 다음과 같이 테스트:

```
@https://www.figma.com/design/lzHEWBZmLDENjELGjlRkyB/Gradi?node-id=2001-405
이 디자인을 확인해줘
```

## 주의사항

⚠️ **보안 중요!**

- `.cursor/mcp.json` 파일은 개인 API 키를 포함하므로 **절대 Git에 커밋하지 마세요**
- `.cursor/` 디렉토리는 이미 `.gitignore`에 포함되어 있습니다
- API 키는 팀원들과 직접 공유하지 말고, 각자 발급받아 사용하세요
- API 키가 노출된 경우 즉시 Figma 설정에서 해당 토큰을 삭제하고 새로 발급받으세요

## 프로젝트 정보

- **Figma 파일**: [Gradi Design](https://www.figma.com/design/lzHEWBZmLDENjELGjlRkyB/Gradi)
- **File Key**: `lzHEWBZmLDENjELGjlRkyB`
- **Node ID**: `2001:405` (기본값)

## 문제 해결

### MCP 서버가 작동하지 않는 경우

1. Node.js가 설치되어 있는지 확인 (`node --version`)
2. `npx` 명령어가 작동하는지 확인
3. Cursor를 완전히 재시작
4. API 키가 올바른지 확인

### "Invalid API key" 오류

- Figma에서 API 키를 새로 발급받고 교체
- API 키 앞에 `figd_` 접두사가 있는지 확인

### 권한 오류

- Figma 파일에 대한 접근 권한이 있는지 확인
- 팀 관리자에게 파일 접근 권한 요청

## 참고 자료

- [Figma Developer API Documentation](https://www.figma.com/developers/api)
- [MCP Protocol Specification](https://modelcontextprotocol.io/)


