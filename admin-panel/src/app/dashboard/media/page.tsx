"use client";

import { useState, useEffect } from "react";
import Sidebar from "@/components/Sidebar";
import Header from "@/components/Header";
import { collection, onSnapshot, addDoc, deleteDoc, updateDoc, doc, serverTimestamp } from "firebase/firestore";
import { db } from "@/lib/firebase";

// Matches app-mobile/lib/models/video_model.dart + MediaProvider._firestoreFetch —
// this is the ONLY path content reaches the app's Media tab (no YouTube API,
// no algorithmic suggestions, by design). Every field here is read by name
// on the app side, so it has to match exactly.
interface MediaItem {
  id: string;
  type: "video" | "quran" | "ruqyah";
  title: string;
  author: string;
  category: string;
  description: string;
  youtubeId: string;
  isActive: boolean;
}

// Where each section appears in the Daily Muslim app. The Quran section of
// the app is now text + audio (not videos) — lectures and tafsir belong in
// Islamic Videos. "quran" is kept only so legacy items still display here.
const SECTIONS: { value: MediaItem["type"]; label: string; help: string }[] = [
  { value: "video", label: "Islamic Videos", help: "Lectures, tafsir, reminders — Media → Islamic Videos." },
  { value: "ruqyah", label: "Ruqyah", help: "Ruqyah recitations — Media → Ruqyah (below the built-in Quran ruqyah)." },
];
const LEGACY_LABELS: Record<string, string> = { quran: "Quran (legacy — not shown in app)" };
const sectionLabel = (t: string) =>
  SECTIONS.find((s) => s.value === t)?.label ?? LEGACY_LABELS[t] ?? t;

function extractYoutubeId(input: string): string | null {
  const trimmed = input.trim();
  const patterns = [
    /(?:youtube\.com\/watch\?v=|youtube\.com\/embed\/|youtube\.com\/shorts\/)([\w-]{11})/,
    /youtu\.be\/([\w-]{11})/,
  ];
  for (const re of patterns) {
    const match = trimmed.match(re);
    if (match) return match[1];
  }
  // Bare 11-character video ID pasted directly
  if (/^[\w-]{11}$/.test(trimmed)) return trimmed;
  return null;
}

export default function MediaManagementPage() {
  const [mediaItems, setMediaItems] = useState<MediaItem[]>([]);
  const [loading, setLoading] = useState(true);

  const [isModalOpen, setIsModalOpen] = useState(false);
  const [section, setSection] = useState<MediaItem["type"]>("video");
  const [title, setTitle] = useState("");
  const [author, setAuthor] = useState("");
  const [category, setCategory] = useState("");
  const [youtubeInput, setYoutubeInput] = useState("");
  const [description, setDescription] = useState("");
  const [formError, setFormError] = useState("");
  const [saving, setSaving] = useState(false);
  const [editingId, setEditingId] = useState<string | null>(null);
  const [filter, setFilter] = useState<"all" | MediaItem["type"]>("all");

  useEffect(() => {
    setLoading(true);
    const unsubscribe = onSnapshot(collection(db, "media"), (snapshot) => {
      const list: MediaItem[] = [];
      snapshot.forEach((d) => {
        list.push({ id: d.id, ...d.data() } as MediaItem);
      });
      setMediaItems(list);
      setLoading(false);
    }, (error) => {
      console.error("Error fetching media:", error);
      setLoading(false);
    });

    return () => unsubscribe();
  }, []);

  const resetForm = () => {
    setEditingId(null);
    setSection("video");
    setTitle("");
    setAuthor("");
    setCategory("");
    setYoutubeInput("");
    setDescription("");
    setFormError("");
  };

  const handleAddMedia = async (e: React.FormEvent) => {
    e.preventDefault();
    setFormError("");
    const youtubeId = extractYoutubeId(youtubeInput);
    if (!youtubeId) {
      setFormError("Couldn't find a valid YouTube video ID in that link.");
      return;
    }
    if (!title.trim()) {
      setFormError("Title is required.");
      return;
    }
    setSaving(true);
    try {
      if (editingId) {
        await updateDoc(doc(db, "media", editingId), {
          type: section,
          title: title.trim(),
          author: author.trim() || "Sunnah Grandeur",
          category: category.trim() || sectionLabel(section),
          description: description.trim(),
          youtubeId,
          thumbnail: `https://img.youtube.com/vi/${youtubeId}/hqdefault.jpg`,
          updatedAt: serverTimestamp(),
        });
        setIsModalOpen(false);
        resetForm();
        return;
      }
      await addDoc(collection(db, "media"), {
        type: section,
        title: title.trim(),
        author: author.trim() || "Sunnah Grandeur",
        category: category.trim() || sectionLabel(section),
        description: description.trim(),
        youtubeId,
        duration: "—",
        views: "0",
        thumbnail: `https://img.youtube.com/vi/${youtubeId}/hqdefault.jpg`,
        isActive: true,
        publishedAt: serverTimestamp(),
        createdAt: serverTimestamp(),
      });
      setIsModalOpen(false);
      resetForm();
    } catch (err) {
      console.error("Error adding media:", err);
      setFormError("Failed to save — please try again.");
    } finally {
      setSaving(false);
    }
  };

  const openEdit = (item: MediaItem) => {
    setEditingId(item.id);
    setSection(item.type === "quran" ? "video" : item.type);
    setTitle(item.title ?? "");
    setAuthor(item.author ?? "");
    setCategory(item.category ?? "");
    setYoutubeInput(item.youtubeId ?? "");
    setDescription(item.description ?? "");
    setFormError("");
    setIsModalOpen(true);
  };

  const toggleActive = async (item: MediaItem) => {
    try {
      await updateDoc(doc(db, "media", item.id), { isActive: !item.isActive, updatedAt: serverTimestamp() });
    } catch (e) {
      console.error("Error toggling media:", e);
    }
  };

  const visibleItems = mediaItems.filter((m) => filter === "all" || m.type === filter);
  const countOf = (t: string) => mediaItems.filter((m) => m.type === t).length;

  const handleDelete = async (id: string) => {
    if (!window.confirm("Remove this video from the app's Media tab?")) return;
    try {
      await deleteDoc(doc(db, "media", id));
    } catch (e) {
      console.error("Error deleting media:", e);
    }
  };

  return (
    <div className="flex">
      <Sidebar />
      <main className="ml-0 md:ml-64 flex-1 flex flex-col min-h-screen relative bento-pattern overflow-hidden">
        <Header title="Media Library" />

        <div className="p-4 sm:p-6 md:p-8 max-w-[1400px] mx-auto w-full relative z-10 space-y-6">
          <div className="flex flex-col sm:flex-row sm:justify-between sm:items-center gap-4 bg-surface-card p-4 sm:p-6 rounded-xl border border-border-subtle shadow-xl">
            <div>
              <h3 className="font-headline-md text-xl text-on-background">Mobile App Media Tab</h3>
              <p className="text-xs text-on-surface-variant mt-1">
                Videos added here are the only content that appears in the app&apos;s Media tab — no automated
                suggestions, no YouTube algorithm. Add a video, and it shows up there right away.
              </p>
            </div>
            <button
              onClick={() => setIsModalOpen(true)}
              className="flex items-center justify-center gap-2 bg-primary text-on-primary px-6 py-2.5 rounded font-label-accent text-xs hover:brightness-110 transition-all shadow-lg shadow-primary/20 shrink-0"
            >
              <span className="material-symbols-outlined text-base">add</span>
              ADD VIDEO
            </button>
          </div>

          <div className="flex flex-wrap gap-2">
            {([["all", `All (${mediaItems.length})`], ...SECTIONS.map((s) => [s.value, `${s.label} (${countOf(s.value)})`]),
              ...(countOf("quran") > 0 ? [["quran", `Legacy Quran (${countOf("quran")})`]] : [])] as [string, string][]).map(([v, label]) => (
              <button
                key={v}
                onClick={() => setFilter(v as typeof filter)}
                className={`px-4 py-2 rounded-full text-xs border transition-colors ${filter === v ? "bg-primary text-on-primary border-primary" : "border-border-subtle text-on-surface-variant hover:border-primary/50"}`}
              >
                {label}
              </button>
            ))}
          </div>

          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-6">
            {loading ? (
              <div className="col-span-full p-12 text-center text-on-surface-variant">
                <div className="animate-spin rounded-full h-8 w-8 border-t-2 border-primary mx-auto mb-4"></div>
                Loading live media...
              </div>
            ) : visibleItems.length === 0 ? (
              <div className="col-span-full p-12 text-center text-on-surface-variant bg-surface-container rounded-xl">
                No videos added yet. Click &apos;Add Video&apos; to add the first one.
              </div>
            ) : (
              visibleItems.map((item) => (
                <div key={item.id} className="bg-surface-card border border-border-subtle rounded-xl overflow-hidden group hover:border-primary/50 transition-colors relative">
                  <div className="h-40 bg-surface-container-high flex items-center justify-center relative border-b border-border-subtle overflow-hidden">
                    {item.youtubeId ? (
                      <img
                        src={`https://img.youtube.com/vi/${item.youtubeId}/hqdefault.jpg`}
                        alt={item.title}
                        className="w-full h-full object-cover group-hover:scale-105 transition-transform"
                      />
                    ) : (
                      <span className="material-symbols-outlined text-4xl text-primary/60">play_circle</span>
                    )}
                    <div className="absolute top-2 right-2 flex gap-1.5">
                      <button
                        onClick={() => openEdit(item)}
                        title="Edit"
                        aria-label="Edit video"
                        className="bg-black/70 text-white rounded-full w-9 h-9 flex items-center justify-center hover:bg-primary hover:text-on-primary"
                      >
                        <span className="material-symbols-outlined text-sm">edit</span>
                      </button>
                      <button
                        onClick={() => toggleActive(item)}
                        title={item.isActive ? "Hide from app" : "Show in app"}
                        aria-label={item.isActive ? "Hide from app" : "Show in app"}
                        className="bg-black/70 text-white rounded-full w-9 h-9 flex items-center justify-center hover:bg-primary hover:text-on-primary"
                      >
                        <span className="material-symbols-outlined text-sm">{item.isActive ? "visibility" : "visibility_off"}</span>
                      </button>
                      <button
                        onClick={() => handleDelete(item.id)}
                        title="Delete"
                        aria-label="Delete video"
                        className="bg-red-500/80 text-white rounded-full w-9 h-9 flex items-center justify-center hover:bg-red-600"
                      >
                        <span className="material-symbols-outlined text-sm">delete</span>
                      </button>
                    </div>
                    <span className={`absolute bottom-2 left-2 text-white text-[10px] uppercase tracking-widest px-2 py-1 rounded ${item.type === "quran" ? "bg-amber-700/90" : "bg-black/70"}`}>
                      {sectionLabel(item.type)}
                    </span>
                    {!item.isActive && (
                      <span className="absolute bottom-2 right-2 bg-zinc-700/90 text-white text-[10px] uppercase tracking-widest px-2 py-1 rounded">Hidden</span>
                    )}
                  </div>
                  <div className="p-4 space-y-1">
                    <h4 className="font-semibold text-sm text-on-background truncate">{item.title}</h4>
                    <p className="text-xs text-on-surface-variant truncate">{item.author}</p>
                  </div>
                </div>
              ))
            )}
          </div>
        </div>

        {isModalOpen && (
          <div className="fixed inset-0 z-[100] bg-black/90 backdrop-blur-sm overflow-y-auto flex items-center justify-center p-4">
            <div className="max-w-[500px] w-full bg-surface-card border border-border-subtle rounded-2xl shadow-2xl max-h-[90vh] overflow-y-auto">
              <div className="px-5 sm:px-8 py-5 sm:py-6 border-b border-border-subtle flex justify-between items-center">
                <h2 className="font-headline-lg text-xl text-primary">{editingId ? "Edit Video" : "Add Video"}</h2>
                <button
                  onClick={() => { setIsModalOpen(false); resetForm(); }}
                  aria-label="Close"
                  className="text-on-surface-variant hover:text-primary transition-colors p-1 -m-1"
                >
                  <span className="material-symbols-outlined">close</span>
                </button>
              </div>
              <form onSubmit={handleAddMedia} className="p-5 sm:p-8 space-y-5">
                {formError && (
                  <div className="bg-red-500/10 border border-red-500/20 text-red-400 text-xs rounded-lg p-3">
                    {formError}
                  </div>
                )}
                <div className="space-y-2">
                  <label className="block text-xs font-label-accent text-primary tracking-widest uppercase">App Section</label>
                  <select
                    value={section}
                    onChange={(e) => setSection(e.target.value as MediaItem["type"])}
                    className="w-full bg-[#1A1A1A] border border-outline-variant rounded px-4 py-3 text-sm focus:outline-none focus:border-primary"
                  >
                    {SECTIONS.map((s) => (
                      <option key={s.value} value={s.value}>{s.label}</option>
                    ))}
                  </select>
                  <p className="text-[11px] text-on-surface-variant">{SECTIONS.find((s) => s.value === section)?.help}</p>
                </div>
                <div className="space-y-2">
                  <label className="block text-xs font-label-accent text-primary tracking-widest uppercase">YouTube Link or Video ID</label>
                  <input
                    value={youtubeInput} onChange={(e) => setYoutubeInput(e.target.value)}
                    className="w-full bg-[#1A1A1A] border border-outline-variant rounded px-4 py-3 text-sm focus:outline-none focus:border-primary"
                    placeholder="https://youtube.com/watch?v=..." required
                  />
                </div>
                <div className="space-y-2">
                  <label className="block text-xs font-label-accent text-primary tracking-widest uppercase">Title</label>
                  <input
                    value={title} onChange={(e) => setTitle(e.target.value)}
                    className="w-full bg-[#1A1A1A] border border-outline-variant rounded px-4 py-3 text-sm focus:outline-none focus:border-primary"
                    placeholder="e.g. The Etiquette of Seeking Knowledge" required
                  />
                </div>
                <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                  <div className="space-y-2">
                    <label className="block text-xs font-label-accent text-primary tracking-widest uppercase">Scholar / Channel</label>
                    <input
                      value={author} onChange={(e) => setAuthor(e.target.value)}
                      className="w-full bg-[#1A1A1A] border border-outline-variant rounded px-4 py-3 text-sm focus:outline-none focus:border-primary"
                      placeholder="e.g. Mufti Menk"
                    />
                  </div>
                  <div className="space-y-2">
                    <label className="block text-xs font-label-accent text-primary tracking-widest uppercase">Series / Topic</label>
                    <input
                      value={category} onChange={(e) => setCategory(e.target.value)}
                      className="w-full bg-[#1A1A1A] border border-outline-variant rounded px-4 py-3 text-sm focus:outline-none focus:border-primary"
                      placeholder="e.g. Tafseer"
                    />
                  </div>
                </div>
                <div className="space-y-2">
                  <label className="block text-xs font-label-accent text-primary tracking-widest uppercase">Description (optional)</label>
                  <textarea
                    value={description} onChange={(e) => setDescription(e.target.value)}
                    rows={2}
                    className="w-full bg-[#1A1A1A] border border-outline-variant rounded px-4 py-3 text-sm focus:outline-none focus:border-primary resize-none"
                  />
                </div>
                <div className="pt-2 flex justify-end gap-4">
                  <button type="button" onClick={() => { setIsModalOpen(false); resetForm(); }} className="text-on-surface-variant text-xs">CANCEL</button>
                  <button type="submit" disabled={saving} className="bg-primary text-on-primary px-6 py-2 rounded text-xs disabled:opacity-50">
                    {saving ? "SAVING..." : editingId ? "SAVE CHANGES" : "ADD VIDEO"}
                  </button>
                </div>
              </form>
            </div>
          </div>
        )}
      </main>
    </div>
  );
}
