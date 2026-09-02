import pandas as pd
import joblib
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.preprocessing import OneHotEncoder, StandardScaler
from sklearn.compose import ColumnTransformer
from sklearn.linear_model import LogisticRegression
from sklearn.pipeline import Pipeline

print("🧠 Reading historical dataset...")
df = pd.read_csv('dataset.csv')

# Separate features and target
X = df[['filename', 'extension', 'size_bytes']]
y = df['target_directory']

print("⚙️ Assembling ColumnTransformer (TF-IDF N-Gram + OneHot + Scaler)...")
preprocessor = ColumnTransformer(
    transformers=[
        ('name_tfidf', TfidfVectorizer(analyzer='char_wb', ngram_range=(3, 5), sublinear_tf=True), 'filename'),
        ('ext_encode', OneHotEncoder(handle_unknown='ignore'), ['extension']),
        ('size_scale', StandardScaler(), ['size_bytes'])
    ]
)

print("🚀 Initializing Logistic Regression (Native Probability Model)...")
# C=100.0 forces the model to be highly confident on training patterns (intentional overfitting for small rulesets)
classifier = LogisticRegression(C=100.0, max_iter=1000)

pipeline = Pipeline(steps=[
    ('preprocessor', preprocessor),
    ('classifier', classifier)
])

print("⏳ Training Micro-ML model...")
# With LogisticRegression, we can fit the entire pipeline seamlessly in one line
pipeline.fit(X, y)

print("💾 Saving model artifact to disk...")
joblib.dump(pipeline, 'micro_sorter.joblib')
print("✅ Done! The model is ready for background inference.")