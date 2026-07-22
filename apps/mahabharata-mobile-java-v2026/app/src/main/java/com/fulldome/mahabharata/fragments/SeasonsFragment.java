package com.fulldome.mahabharata.fragments;

import android.os.Bundle;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.fragment.app.Fragment;
import androidx.recyclerview.widget.RecyclerView;

import com.fulldome.mahabharata.R;
import com.fulldome.mahabharata.adapters.SeasonsAdapter;
import com.fulldome.mahabharata.decorations.StartEndPaddingDecorations;
import com.fulldome.mahabharata.model.Seasons;
import com.ironwaterstudio.utils.UiHelper;

public class SeasonsFragment extends Fragment {
    private RecyclerView rvSeasons;
    private SeasonsAdapter adapter;

    @Nullable
    @Override
    public View onCreateView(@NonNull final LayoutInflater inflater, @Nullable final ViewGroup container,
                             @Nullable final Bundle savedInstanceState) {
        final View v = inflater.inflate(R.layout.fragment_seasons, container, false);
        rvSeasons = v.findViewById(R.id.rv_seasons); // <--
        return v;
    }

    @Override
    public void onActivityCreated(@Nullable final Bundle inState) {
        super.onActivityCreated(inState);
        adapter = new SeasonsAdapter(getContext(), Seasons.getInstance());
        rvSeasons.setAdapter(adapter);
        rvSeasons.addItemDecoration(new StartEndPaddingDecorations(UiHelper.dpToPx(getContext(), 8)));
    }

    public void updateAllViews() {
        if (adapter != null && getActivity() != null) {
            adapter.notifyDataSetChanged();
        }
    }
}
