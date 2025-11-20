#!/usr/bin/env python3
"""
app.py - FastAPI 服务
提供 /chat 接口，基于 FAISS 索引进行 RAG 问答
"""
import os
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from langchain_openai import OpenAIEmbeddings, ChatOpenAI
from langchain_community.vectorstores import FAISS
from langchain.chains import RetrievalQA
from langchain.prompts import PromptTemplate

# 检查 API Key
if not os.getenv("OPENAI_API_KEY"):
    raise ValueError("请设置环境变量 OPENAI_API_KEY")

app = FastAPI(title="RAG Demo API")

# 加载 FAISS 索引
print("🔄 正在加载 FAISS 索引...")
embeddings = OpenAIEmbeddings()
vectorstore = FAISS.load_local(
    "faiss_index", 
    embeddings,
    allow_dangerous_deserialization=True
)
print("✅ FAISS 索引加载完成")

# 创建 LLM
llm = ChatOpenAI(
    model="gpt-4o-mini",
    temperature=0.7,
)

# 自定义 Prompt
prompt_template = """你是一个知识问答助手。请根据以下检索到的上下文回答用户的问题。

如果上下文中没有相关信息，请礼貌地告诉用户"知识库中可能没有相关内容"。

上下文：
{context}

问题：{question}

回答："""

PROMPT = PromptTemplate(
    template=prompt_template,
    input_variables=["context", "question"]
)

# 创建 QA Chain
qa_chain = RetrievalQA.from_chain_type(
    llm=llm,
    chain_type="stuff",
    retriever=vectorstore.as_retriever(search_kwargs={"k": 3}),
    chain_type_kwargs={"prompt": PROMPT},
    return_source_documents=False,
)

class ChatRequest(BaseModel):
    question: str

class ChatResponse(BaseModel):
    answer: str

@app.get("/")
def read_root():
    return {
        "message": "RAG Demo API is running",
        "endpoints": {
            "/chat": "POST - 发送问题获取答案",
            "/health": "GET - 健康检查"
        }
    }

@app.get("/health")
def health_check():
    return {"status": "healthy"}

@app.post("/chat", response_model=ChatResponse)
def chat(request: ChatRequest):
    if not request.question or not request.question.strip():
        raise HTTPException(status_code=400, detail="问题不能为空")
    
    try:
        result = qa_chain.invoke({"query": request.question})
        answer = result.get("result", "抱歉，无法生成回答")
        return ChatResponse(answer=answer)
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"处理问题时出错：{str(e)}")

if __name__ == "__main__":
    import uvicorn
    port = int(os.getenv("PORT", 8000))
    uvicorn.run(app, host="0.0.0.0", port=port)

