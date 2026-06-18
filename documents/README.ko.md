# Free PDF Editor 한국어 문서

## 결론

Free PDF Editor는 **PDFKit 위에 편집 엔진을 얹은 macOS 네이티브 PDF 편집 앱**입니다. v0.0.1에서는 PDF 열기, 텍스트 인식 기반 교체, 하이라이트, 텍스트 박스, 코멘트, 도형, 스탬프, 서명 등록/삽입, 저장/flatten export를 제공합니다.

## 설치

배포 파일:

```text
dist/FreePDFEditor-v0.0.1.dmg
```

DMG를 열고 **Free PDF Editor.app**을 Applications로 드래그하면 됩니다.

현재 빌드는 로컬 배포용 ad-hoc 서명입니다. 공개 배포용으로는 Apple Developer ID 서명과 notarization이 필요합니다.

## 주요 기능

| 기능 | 설명 |
|---|---|
| PDF 보기 | PDFKit 기반 네이티브 렌더링, 페이지 이동, 썸네일, 확대/축소 |
| 텍스트 교체 | PDF 텍스트 줄을 클릭해 인식하고, Mac 기본 폰트/크기/색상으로 새 텍스트를 덮어쓰기 |
| 주석 | 하이라이트, 밑줄, 취소선, 텍스트 박스, 코멘트 |
| 도형/스탬프 | 사각형, 원, 선, APPROVED 같은 텍스트 스탬프 |
| 서명 | 직접 그려서 저장하거나 이미지 파일을 가져와 PDF 위에 배치 |
| 저장 | 편집 가능한 annotation 저장 또는 flattened PDF export |

## 텍스트 수정 방식

이 앱의 텍스트 수정은 PDF 내부 content stream을 직접 삭제/수정하는 방식이 아닙니다. 실제 구조는 다음과 같습니다.

```text
1. PDFKit으로 클릭한 텍스트 줄과 좌표를 찾음
2. inspector에서 수정할 텍스트, 폰트, 크기, 색상을 선택
3. 기존 텍스트 영역을 cover color로 가림
4. 새 텍스트 annotation을 같은 위치에 배치
5. 일반 저장 또는 flattened export 수행
```

따라서 흰 배경 양식, 계약서, 증명서, 신청서처럼 레이아웃이 단순한 PDF에 적합합니다. 개인정보 완전 삭제나 법적 redaction 용도에는 별도 보안 redaction 기능이 필요합니다.

## 사용 방법

1. **Open PDF**로 PDF를 엽니다.
2. 상단 도구에서 **Replace Text**를 선택합니다.
3. 수정할 PDF 텍스트 줄을 클릭합니다.
4. 오른쪽 inspector에서 새 텍스트와 폰트/크기/색상을 수정합니다.
5. **Apply**를 누릅니다.
6. 서명이 필요하면 **Sign** 탭에서 Draw 또는 Import로 서명을 등록합니다.
7. 상단 **Signature** 도구를 선택하고 PDF 위 원하는 위치를 클릭합니다.
8. 저장은 `Cmd+S`, 최종 공유본은 **Export Flattened PDF**를 사용합니다.

## 키보드 단축키

| 단축키 | 동작 |
|---|---|
| `Command + O` | PDF 열기 |
| `Command + S` | 저장 |
| `Command + Shift + S` | 다른 이름으로 저장 |
| `Command + Left Arrow` | 이전 페이지 |
| `Command + Right Arrow` | 다음 페이지 |
| `Command + =` | 확대 |
| `Command + -` | 축소 |
| `Command + 0` | 실제 크기 |
| `Command + Option + S` | 페이지 썸네일 토글 |
| `Command + Option + I` | 인스펙터 토글 |
| `Command + 1` ... `Command + 9` | 주요 편집 도구 전환 |
| `Delete` | 선택한 annotation 삭제 |

## 주의

- 복잡한 배경 위 텍스트는 cover color가 티날 수 있습니다.
- 스캔 PDF는 원본 텍스트 객체가 없으므로 OCR 기반 기능이 추가로 필요합니다.
- flattened export는 시각적으로 주석을 굳히지만, 보안 redaction과 동일하지 않습니다.
